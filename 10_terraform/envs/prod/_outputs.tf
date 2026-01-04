locals {
  single_hosts = [
    module.ci_runner_01,
    module.core_nas_01,
    module.core_networking,

    module.docs_01,
    module.observability_01,
  ]

  all_hosts = concat(
    local.single_hosts,
    values(module.databases),
    values(module.media)
  )

  ansible_inventory = {
    for role in distinct([for h in local.all_hosts : h.ansible_role]) :
    role => {
      for h in local.all_hosts :
      h.name => h.ipv4_address
      if h.ansible_role == role
    }
  }
}

output "ansible_hosts" {
  value = local.ansible_inventory
}

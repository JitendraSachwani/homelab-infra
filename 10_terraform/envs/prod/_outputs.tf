locals {
  single_hosts = [
    module.core_ci_runner_01,
    module.core_nas,
    module.core_networking,
    module.core_stack,

    module.docs_01,
    module.observability_01,
  ]

  all_hosts = concat(
    local.single_hosts,
    values(module.databases),
    values(module.media),
    values(module.market_diaries)
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

output "gateway_public_ip" {
  value = module.oracle_cloud_gateway.gateway_public_ip
}

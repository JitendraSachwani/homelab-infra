locals {
  all_hosts = [
    module.ci_runner_01,
    module.pihole_01,
    module.nas_01,

    module.db_redis_01,
    module.db_mysql_01,
    module.db_postgres_01,
    module.db_mongo_01,
    
    module.docs_01,
    
    module.media_mgmt_01,
    module.media_srv_01,
    
    module.observability_01,
  ]

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

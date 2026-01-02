locals {
  databases = {
    redis = {
      name         = "prod-redis-01"
      vm_id        = 20001
      role         = "db_redis"
      ip           = "10.0.2.0/16"
      cores        = 1
      memory_mb    = 512
      disk_gb      = 10
    }

    mysql = {
      name         = "prod-mysql-01"
      vm_id        = 20101
      role         = "db_mysql"
      ip           = "10.0.2.1/16"
      cores        = 2
      memory_mb    = 2048
      disk_gb      = 50
    }

    postgres = {
      name         = "prod-postgres-01"
      vm_id        = 20201
      role         = "db_postgres"
      ip           = "10.0.2.2/16"
      cores        = 2
      memory_mb    = 2048
      disk_gb      = 50
    }

    mongo = {
      name         = "prod-mongo-01"
      vm_id        = 20301
      role         = "db_mongo"
      ip           = "10.0.2.3/16"
      cores        = 2
      memory_mb    = 2048
      disk_gb      = 50
    }
  }
}

module "databases" {
  for_each = local.databases

  source = "../../modules/proxmox_vm"
  providers = {
    proxmox = proxmox
  }

  name          = each.value.name
  vm_id         = each.value.vm_id
  ansible_role  = each.value.role

  ipv4_address = each.value.ip
  ipv4_gateway = "10.0.0.1"

  cores      = each.value.cores
  cpu_type   = "host"
  memory_mb  = each.value.memory_mb
  disk_gb    = each.value.disk_gb

  cloud_init_file_id = proxmox_virtual_environment_file.cloud_init_file.id
  import_disk_id = proxmox_virtual_environment_download_file.ubuntu_22_jammy_qcow2.id
}
module "db_redis_01" {
  source = "../../modules/proxmox_vm"
  providers = {
    proxmox = proxmox
  }

  name  = "prod-redis-01"
  vm_id = 20001
  ansible_role  = "db_redis"

  ipv4_address = "10.0.2.0/16"
  ipv4_gateway = "10.0.0.1"

  cores = 1
  memory_mb = 512
  disk_gb = 20

  cloud_init_file_id = proxmox_virtual_environment_file.cloud_init_file.id
  import_disk_id = proxmox_virtual_environment_download_file.ubuntu_22_jammy_qcow2.id
}

module "db_mysql_01" {
  source = "../../modules/proxmox_vm"

  providers = {
    proxmox = proxmox
  }

  name  = "prod-mysql-01"
  vm_id = 20101
  ansible_role  = "db_mysql"

  ipv4_address = "10.0.2.1/16"
  ipv4_gateway = "10.0.0.1"

  cores = 2
  memory_mb = 2048
  disk_gb = 50

  cloud_init_file_id = proxmox_virtual_environment_file.cloud_init_file.id
  import_disk_id = proxmox_virtual_environment_download_file.ubuntu_22_jammy_qcow2.id
}

module "db_postgres_01" {
  source = "../../modules/proxmox_vm"
  providers = {
    proxmox = proxmox
  }

  name  = "prod-postgres-01"
  vm_id = 20201
  ansible_role  = "db_postgres"

  ipv4_address = "10.0.2.2/16"
  ipv4_gateway = "10.0.0.1"

  cores = 2
  memory_mb = 2048
  disk_gb = 50

  cloud_init_file_id = proxmox_virtual_environment_file.cloud_init_file.id
  import_disk_id = proxmox_virtual_environment_download_file.ubuntu_22_jammy_qcow2.id
}

module "db_mongo_01" {
  source = "../../modules/proxmox_vm"
  providers = {
    proxmox = proxmox
  }

  name  = "prod-mongo-01"
  vm_id = 20301
  ansible_role  = "db_mongo"

  ipv4_address = "10.0.2.3/16"
  ipv4_gateway = "10.0.0.1"

  cores = 2
  memory_mb = 2048
  disk_gb = 50

  cloud_init_file_id = proxmox_virtual_environment_file.cloud_init_file.id
  import_disk_id = proxmox_virtual_environment_download_file.ubuntu_22_jammy_qcow2.id
}

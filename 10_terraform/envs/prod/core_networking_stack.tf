module "core_networking" {
  source = "../../modules/proxmox_vm"
  providers = {
    proxmox = proxmox
  }

  name         = "prod-core-networking-01"
  vm_id        = 10401
  ansible_role = "networking"

  ipv4_address = "10.0.1.4/16"
  ipv4_gateway = "10.0.0.1"

  cores     = 2
  memory_mb = 2048

  cloud_init_file_id = proxmox_virtual_environment_file.cloud_init_file.id
  import_disk_id     = proxmox_virtual_environment_download_file.ubuntu_22_jammy_qcow2.id
}

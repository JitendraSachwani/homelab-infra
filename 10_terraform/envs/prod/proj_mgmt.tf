module "proj_mgmt" {
  source = "../../modules/proxmox_vm"

  providers = {
    proxmox = proxmox
  }

  name         = "prod-proj-mgmt-01"
  vm_id        = 60001
  ansible_role = "proj_mgmt"

  ipv4_address = "10.0.6.0/16"
  ipv4_gateway = "10.0.0.1"

  cores     = 2
  memory_mb = 4096

  cloud_init_file_id = proxmox_virtual_environment_file.cloud_init_file.id
  import_disk_id     = proxmox_virtual_environment_download_file.ubuntu_22_jammy_qcow2.id
}

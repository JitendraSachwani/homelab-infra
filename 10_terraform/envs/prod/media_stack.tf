module "media_stack" {
  source = "../../modules/proxmox_vm"
  providers = {
    proxmox = proxmox
  }

  name         = "prod-media-stack-01"
  vm_id        = 50001
  ansible_role = "media_stack"

  ipv4_address = "10.0.5.0/16"
  ipv4_gateway = "10.0.0.1"

  cores     = 4
  memory_mb = 6144

  cloud_init_file_id = proxmox_virtual_environment_file.cloud_init_file.id
  import_disk_id     = proxmox_virtual_environment_download_file.ubuntu_22_jammy_qcow2.id
}

module "docs_01" {
  source = "../../modules/proxmox_vm"

  providers = {
    proxmox = proxmox
  }

  name         = "prod-docs-01"
  vm_id        = 40001
  ansible_role = "docs"

  ipv4_address = "10.0.4.0/16"
  ipv4_gateway = "10.0.0.1"

  cores     = 1
  memory_mb = 512

  cloud_init_file_id = proxmox_virtual_environment_file.cloud_init_file.id
  import_disk_id     = proxmox_virtual_environment_download_file.ubuntu_22_jammy_qcow2.id
}

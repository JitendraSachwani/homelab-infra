module "logging_01" {
  source = "../../modules/proxmox_vm"

  providers = {
    proxmox = proxmox
  }

  name  = "prod-logging-01"
  vm_id = 30101
  tags = ["role-logging"]
  
  cores = 2
  memory_mb = 1024

  cloud_init_file_id = proxmox_virtual_environment_file.cloud_init_file.id
  import_disk_id = proxmox_virtual_environment_download_file.ubuntu_22_jammy_qcow2.id
}

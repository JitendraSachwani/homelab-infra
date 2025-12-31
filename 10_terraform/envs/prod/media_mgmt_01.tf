module "media_mgmt_01" {
  source = "../../modules/proxmox_vm"

  providers = {
    proxmox = proxmox
  }

  name  = "prod-media-mgmt-01"
  vm_id = 50201
  ansible_role  = "media_mgmt"
  
  cores = 2
  memory_mb = 3072

  cloud_init_file_id = proxmox_virtual_environment_file.cloud_init_file.id
  import_disk_id = proxmox_virtual_environment_download_file.ubuntu_22_jammy_qcow2.id
}

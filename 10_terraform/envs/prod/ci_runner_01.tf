module "ci_runner_01" {
  source = "../../modules/proxmox_vm"
  providers = {
    proxmox = proxmox
  }

  name         = "prod-ci-runner-01"
  vm_id        = 10301
  ansible_role = "ci_runner"

  ipv4_address = "10.0.1.3/16"
  ipv4_gateway = "10.0.0.1"

  cores     = 2
  memory_mb = 2048
  
  cloud_init_file_id = proxmox_virtual_environment_file.cloud_init_file.id
  import_disk_id     = proxmox_virtual_environment_download_file.ubuntu_22_jammy_qcow2.id
}

module "ci_runner_01" {
  source = "../../modules/proxmox_vm"

  providers = {
    proxmox = proxmox
  }

  name  = "prod-ci-runner-02"
  vm_id = 10102
  cloud_init_file_id = proxmox_virtual_environment_file.ci_runner_cloud_init.id
  import_disk_id = proxmox_virtual_environment_download_file.ubuntu_22_jammy_qcow2.id

  tags = concat(local.common_tags, ["role-ci"])
}

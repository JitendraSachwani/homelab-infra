module "ci_runner" {
  source = "../modules/proxmox_vm"

  name  = "prod-ci-runner-02"
  vm_id = 10102
  cloud_init_file_id = proxmox_virtual_environment_file.ci_runner_cloud_init.id

  tags = concat(local.common_tags, ["role-ci"])
}

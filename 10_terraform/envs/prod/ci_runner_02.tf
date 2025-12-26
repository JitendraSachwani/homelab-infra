module "ci_runner" {
  source = "../../modules/proxmox_vm"

  providers = {
    proxmox = proxmox
  }

  name  = "prod-ci-runner-02"
  vm_id = 10102
  cloud_init_file_id = proxmox_virtual_environment_file.ci_runner_cloud_init.id

  tags = concat(local.common_tags, ["role-ci"])
}

output "ansible_hosts" {
  value = {
    ci_runners = {
      module.ci_runner.name => module.ci_runner.ipv4_address
    }
  }
}
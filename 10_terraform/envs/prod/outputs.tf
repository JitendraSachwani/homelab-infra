output "ansible_hosts" {
  value = {
    ci_runners = {
      module.ci_runner_02.name = module.ci_runner_02.ipv4_address
    }
  }
}

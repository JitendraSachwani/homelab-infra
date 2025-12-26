output "ansible_hosts" {
  value = {
    ci_runners = {
      for m in [
        module.ci_runner_02
      ] :
      m.name => m.ipv4_address
    }
  }
}

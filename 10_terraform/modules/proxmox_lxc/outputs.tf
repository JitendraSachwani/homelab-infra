output "ipv4_address" {
  description = "Primary IPv4 address of the VM"
  value       = try(
    proxmox_virtual_environment_vm.this.ipv4_addresses[1][0],
    null
  )
}

output "name" {
  description = "VM Name"
  value = var.name
}

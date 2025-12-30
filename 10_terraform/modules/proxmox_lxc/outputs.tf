output "ipv4_address" {
  description = "Primary IPv4 address of the VM"
  value       = try(
    proxmox_virtual_environment_container.this.ipv4[0],
    null
  )
}

output "name" {
  description = "VM Name"
  value = var.name
}

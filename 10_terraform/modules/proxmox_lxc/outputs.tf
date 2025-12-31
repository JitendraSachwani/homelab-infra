output "name" {
  description = "VM Name"
  value = var.name
}

output "ansible_role" {
  value = var.ansible_role
}

output "ipv4_address" {
  description = "Primary IPv4 address of the VM"
  value       = proxmox_virtual_environment_container.this.ipv4["veth0"]
}

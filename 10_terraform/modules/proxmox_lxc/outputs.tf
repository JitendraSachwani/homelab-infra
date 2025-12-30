output "vm_id" {
  value = proxmox_lxc.this.vm_id
}

output "hostname" {
  value = proxmox_lxc.this.hostname
}

output "ipv4" {
  value = var.ipv4_address
}

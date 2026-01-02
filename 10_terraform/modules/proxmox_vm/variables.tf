variable "vm_id" {
  description = "Unique VMID for the VM"
  type        = number
}

variable "name" {
  description = "VM name / hostname"
  type        = string
}

variable "ansible_role" {
  type        = string
  description = "Ansible role/group name for inventory generation"
}

variable "node_name" {
  type = string
  description = "Proxmox node name"
  default = "pve"
}

variable "cloud_init_file_id" {
  description = "Cloud-init snippet file ID"
  type        = string
}

variable "datastore_id" {
  type = string
  default = "local-btrfs"
}

variable "ipv4_address" {
  description = "Static IPv4 address (DHCP)"
  type        = string
  default     = null
}

variable "ipv4_gateway" {
  type        = string
  description = "IPv4 gateway"
  default     = null
}

variable "cores" {
  type    = number
  default = 2
}

variable "cpu_type" {
  type    = string
  default = "x86-64-v2-AES"
}

variable "memory_mb" {
  type    = number
  default = 2048
}

variable "disk_gb" {
  type    = number
  default = 20
}

variable "import_disk_id" {
  description = "QCOW2 image file ID"
  type        = string
}

variable "bridge" {
  type = string
  default = "vmbr0"
}

variable "os_type" {
  type    = string
  default = "l26"
}

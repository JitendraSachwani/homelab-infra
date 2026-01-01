variable "vm_id" {
  description = "Unique VMID for the LXC"
  type        = number
}

variable "name" {
  description = "LXC name / hostname"
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

variable "unprivileged" {
  type        = bool
  default     = true
}

variable "nesting" {
  type        = bool
  default     = true
}

variable "ipv4_address" {
  description = "Static IPv4 address (DHCP)"
  type        = string
}

variable "ipv4_gateway" {
  type        = string
  description = "IPv4 gateway"
  default     = null
}

variable "datastore_id" {
  type        = string
  default     = "local-btrfs"
}

variable "cores" {
  type        = number
  default     = 1
}

variable "memory_mb" {
  type        = number
  default     = 512
}

variable "swap_mb" {
  type        = number
  default     = 512
}

variable "disk_gb" {
  type        = string
  default     = 10
}

variable "template_file_id" {
  type        = string
  description = "LXC template file ID"
}

variable "bridge" {
  type        = string
  default     = "vmbr0"
}


variable "vm_id" {
  description = "Proxmox VM ID"
  type        = number
}

variable "name" {
  description = "VM name / hostname"
  type        = string
}

variable "cloud_init_file_id" {
  description = "Cloud-init snippet file ID"
  type        = string
}

variable "import_disk_id" {
  description = "QCOW2 image file ID"
  type        = string
}

variable "node_name" {
  type = string
  default = "pve"
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "datastore_id" {
  type = string
  default = "local-btrfs"
}

variable "ip_address" {
  description = "Static IPv4 address (null = DHCP)"
  type        = string
  default     = null
}

variable "cores" {
  type    = number
  default = 2
}

variable "memory_mb" {
  type    = number
  default = 2048
}

variable "disk_gb" {
  type    = number
  default = 20
}

variable "bridge" {
  type = string
  default = "vmbr0"
}

variable "os_type" {
  type    = string
  default = "l26"
}

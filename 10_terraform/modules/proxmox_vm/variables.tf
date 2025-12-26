variable "vm_id" {
  description = "Proxmox VM ID"
  type        = number
}

variable "name" {
  description = "VM name / hostname"
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

variable "common_tags" {
  type    = list(string)
  default = [
    "env-prod",
    "managed_by-terraform"
  ]
}

variable "datastore_id" {
  type = string
  default = "local-btrfs"
}

variable "cloud_init_file_id" {
  description = "Cloud-init snippet file ID"
  type        = string
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

variable "import_disk_id" {
  description = "QCOW2 image file ID"
  type        = string
  default     = null
}

variable "bridge" {
  type = string
  default = "vmbr0"
}

variable "os_type" {
  type    = string
  default = "l26"
}

variable "proxmox_endpoint" {
  type = string
  default = "https://192.168.1.2:8006/api2/json"
}

variable "proxmox_username" {
  type = string
  default = "root@pam"
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
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

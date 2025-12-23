variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "admin_ssh_public_key" {
  type        = string
  description = "Admin SSH public key"
}

variable "iac_ssh_public_key" {
  type        = string
  description = "IaC SSH public key"
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

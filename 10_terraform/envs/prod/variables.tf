variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_username" {
  type = string
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

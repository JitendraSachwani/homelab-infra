variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VM access"
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDYkMRx4ynSGF9pCQvJgbk+Ff4i9xI72I5WNAm5I7y49GajmIwUQ5YGwLsq4BWf27aCV7gktZT90dtxVV8uI16jQkaAxZoxOcX4dsYEa/25nlabkBm6vvDRW+m46D6S4L5RSI5LRIZiRhggSiFmhX50SC+h1TajNcxfZj9qTsm/7iho1/AV80aelOH5iE1u68VIk1NWr4mZ4cxF+k8UlXFzVNkYE28ulFdbjEv2xHyQTAgbUDgqRkMoTHA5sowpossk54pyGcU94GxCRPORAsZSLQqar2HoLeG3yRs3q8rzX9RrDv8+lf+9y2+LNCbDN31r3W/yH8iJJ1rVpkoSLnX+IOORWMPE3fji7KpSmyLElPeJQAOVRP4n2ZzWae6HIiKLg14O1YTq7C/uC7XlKSXtSFoHWGpfwskb6ZGu8dlzZ5+WRkwxJXQD+QeyJBXgy0r/zN2yix+BmGTpK/+oWe4tcx0b7NzBY1Sg7FF465oKyTExb9HkZLYHlmKPtKWisO0= sachw@DESKTOP-5JGQPLC"
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

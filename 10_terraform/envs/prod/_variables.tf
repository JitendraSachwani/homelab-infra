# -----------------------------------------------
# General Variables
# -----------------------------------------------

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "admin_ssh_public_key" {
  description = "Admin SSH public key"
  type        = string
}

variable "iac_ssh_public_key" {
  description = "IaC SSH public key"
  type        = string
}

# -----------------------------------------------
# OCI Variables
# -----------------------------------------------

variable "oci_user_ocid" {
  description = "OCI API User ocid"
  type        = string
}
variable "oci_fingerprint" {
  description = "OCI API fingerprint"
  type        = string
}

variable "oci_tenancy_ocid" {
  description = "OCI API Tenacy ocid"
  type        = string
}

# -----------------------------------------------
# Proxmox Variables
# -----------------------------------------------

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint"
  type        = string
  default     = "https://10.0.0.3:8006/api2/json"
}

variable "proxmox_username" {
  description = "Proxmox API username"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox API password"
  type        = string
  sensitive   = true
}

variable "oci_tenancy_ocid" {
  description = "OCI API Tenacy ocid"
  type        = string
}

variable "gateway_name" {
  description = "Cloud gateway instance display name"
  type        = string
}

variable "gateway_ansible_role" {
  description = "Ansible role/group name for inventory generation"
  type        = string
}

variable "gateway_shape" {
  description = "OCI compute shape for the cloud gateway"
  type        = string
}

variable "gateway_ocpus" {
  description = "OCPUs for flexible OCI shapes"
  type        = number
  default     = 1
}

variable "gateway_memory_gb" {
  description = "Memory in GB for flexible OCI shapes"
  type        = number
  default     = 6
}

variable "oci_vcn_cidr_blocks" {
  description = "The list of one or more IPv4 CIDR blocks for the VCN. Note: cidr_blocks update must be restricted to one operation at a time (either add/remove or modify one single cidr_block) or the operation will be declined. new cidr_block to be added must be placed at the end of the list."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "oci_public_subnet_cidr_block" {
  description = "The CIDR for the Public Subnet of the vcn."
  type        = string
  default     = "10.0.0.0/24"
}

variable "oci_private_subnet_cidr_block" {
  description = "The CIDR for the Private Subnet of the vcn."
  type        = string
  default     = "10.0.1.0/24"
}

variable "gateway_image_ocid" {
  description = "OCI image OCID for the cloud gateway instance. Leave empty to use the latest matching Ubuntu image."
  type        = string
  default     = ""
}

variable "gateway_image_operating_system" {
  description = "Operating system name used when gateway_image_ocid is empty"
  type        = string
  default     = "Canonical Ubuntu"
}

variable "gateway_image_operating_system_version" {
  description = "Operating system version used when gateway_image_ocid is empty"
  type        = string
  default     = "22.04"
}

variable "gateway_ssh_public_key" {
  description = "SSH public key allowed for the iac user on the cloud gateway"
  type        = string
}

variable "gateway_ssh_allowed_cidrs" {
  description = "CIDRs allowed to SSH into the cloud gateway"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

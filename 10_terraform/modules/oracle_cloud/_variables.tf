variable "oci_tenancy_ocid" {
  description = "OCI API Tenacy ocid"
  type        = string
}

variable "oci_vcn_cidr_blocks" {
  description = "The list of one or more IPv4 CIDR blocks for the VCN. Note: cidr_blocks update must be restricted to one operation at a time (either add/remove or modify one single cidr_block) or the operation will be declined. new cidr_block to be added must be placed at the end of the list."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

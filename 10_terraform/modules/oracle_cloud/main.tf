resource "oci_identity_compartment" "homelab_tf_compartment" {
  # https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-compartment.htm#gather-info
  compartment_id = var.oci_tenancy_ocid

  name          = "homelab_tf_compartment"
  description   = "Compartment for Terraform managed resources."
  enable_delete = false
}

resource "oci_core_vcn" "homelab_tf_vcn" {
  compartment_id = oci_identity_compartment.homelab_tf_compartment.id
  display_name   = "homelab_tf_vcn"
  dns_label      = "tfvcn"
  cidr_blocks    = var.oci_vcn_cidr_blocks
}

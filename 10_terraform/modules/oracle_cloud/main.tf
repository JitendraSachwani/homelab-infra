resource "oci_identity_compartment" "homelab_tf_compartment" {
  # https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-compartment.htm#gather-info
  compartment_id = var.oci_tenancy_ocid

  name          = "homelab_tf"
  description   = "Compartment for Terraform managed resources."
  enable_delete = false
}

resource "oci_core_vcn" "test_vcn" {
  compartment_id = oci_identity_compartment.homelab_tf_compartment.id
  display_name   = "homelab_tf_vcn"
  dns_label      = "tf.vcn1"
  cidr_blocks    = var.oci_vcn_cidr_blocks
}

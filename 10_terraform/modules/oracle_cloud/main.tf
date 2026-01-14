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

resource "oci_core_subnet" "tf_public_subnet" {
    compartment_id = oci_identity_compartment.homelab_tf_compartment.id
    vcn_id = oci_core_vcn.homelab_tf_vcn.id
    display_name = "tf_public_subnet"
    dns_label = "tfpubsubnet"
    cidr_block = var.oci_public_subnet_cidr_block       
}

resource "oci_core_subnet" "tf_private_subnet" {
    compartment_id = oci_identity_compartment.homelab_tf_compartment.id
    vcn_id = oci_core_vcn.homelab_tf_vcn.id
    display_name = "tf_private_subnet"
    dns_label = "tfprivsubnet"
    cidr_block = var.oci_private_subnet_cidr_block
}

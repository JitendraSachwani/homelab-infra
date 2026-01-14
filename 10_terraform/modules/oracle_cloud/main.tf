resource "oci_identity_compartment" "homelab_tf_compartment" {
  # https://docs.oracle.com/en-us/iaas/Content/dev/terraform/tutorials/tf-compartment.htm#gather-info
  compartment_id = var.oci_tenancy_ocid

  name          = "homelab_tf"
  description   = "Compartment for Terraform managed resources."
  enable_delete = false
}

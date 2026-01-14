module "cloud_gateway" {
  source = "../../modules/oracle_cloud"
  providers = {
    oci = oci
  }

  oci_tenancy_ocid = var.oci_tenancy_ocid

}

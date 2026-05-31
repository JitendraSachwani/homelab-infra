module "cloud_gateway" {
  source = "../../modules/oracle_cloud"
  providers = {
    oci = oci
  }

  oci_tenancy_ocid = var.oci_tenancy_ocid
  gateway_name     = "prod-cloud-gateway-01"

  gateway_ssh_public_key = var.iac_ssh_public_key
}

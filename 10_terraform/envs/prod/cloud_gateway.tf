module "cloud_gateway" {
  source = "../../modules/oracle_cloud"
  providers = {
    oci = oci
  }

}

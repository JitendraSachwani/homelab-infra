module "cloud_gateway" {
  source = "../../modules/oracle_cloud"
  providers = {
    oci = oci
  }

  oci_tenancy_ocid = var.oci_tenancy_ocid
  gateway_name     = "prod-cloud-gateway-01"

  gateway_ocpus = 1
  # gateway_shape     = "VM.Standard.E2.1.Micro"
  # gateway_memory_gb = 1
  gateway_shape     = "VM.Standard.A1.Flex"
  gateway_memory_gb = 6

  iac_ssh_public_key   = var.iac_ssh_public_key
  admin_ssh_public_key = var.admin_ssh_public_key

  gateway_ansible_role = "cloud_gateway"
}

output "tf_compartment_ocid" {
  value = oci_identity_compartment.homelab_tf_compartment.id
}

output "tf_compartment_name" {
  value = oci_identity_compartment.homelab_tf_compartment.name
}

output "gateway_host" {
  value = {
    name         = var.gateway_name
    ansible_role = var.gateway_ansible_role
    ipv4_address = oci_core_instance.gateway.public_ip
  }
}

output "gateway_public_ip" {
  value = oci_core_instance.gateway.public_ip
}

output "gateway_private_ip" {
  value = oci_core_instance.gateway.private_ip
}

output "gateway_id" {
  value = oci_core_instance.gateway.id
}

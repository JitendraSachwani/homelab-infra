output "tf_compartment_ocid" {
  value = oci_identity_compartment.homelab_tf_compartment.id
}

output "tf_compartment_name" {
  value = oci_identity_compartment.homelab_tf_compartment.name
}

# output "instance_private_ips" {
#   value = ["${oci_core_instance.TFInstance.*.private_ip}"]
# }

# output "instance_public_ips" {
#   value = ["${oci_core_instance.TFInstance.*.public_ip}"]
# }

# output "instance_id" {
#   value = oci_core_instance.gateway.id
# }

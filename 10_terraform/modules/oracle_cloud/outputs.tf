output "instance_private_ips" {
  value = ["${oci_core_instance.TFInstance.*.private_ip}"]
}

output "instance_public_ips" {
  value = ["${oci_core_instance.TFInstance.*.public_ip}"]
}

# output "instance_id" {
#   value = oci_core_instance.gateway.id
# }

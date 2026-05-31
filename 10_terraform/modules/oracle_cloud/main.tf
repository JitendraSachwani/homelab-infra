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

resource "oci_core_internet_gateway" "tf_internet_gateway" {
  compartment_id = oci_identity_compartment.homelab_tf_compartment.id
  vcn_id         = oci_core_vcn.homelab_tf_vcn.id
  display_name   = "tf_internet_gateway"
  enabled        = true
}

resource "oci_core_route_table" "tf_public_route_table" {
  compartment_id = oci_identity_compartment.homelab_tf_compartment.id
  vcn_id         = oci_core_vcn.homelab_tf_vcn.id
  display_name   = "tf_public_route_table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.tf_internet_gateway.id
  }
}

resource "oci_core_security_list" "tf_public_security_list" {
  compartment_id = oci_identity_compartment.homelab_tf_compartment.id
  vcn_id         = oci_core_vcn.homelab_tf_vcn.id
  display_name   = "tf_public_security_list"

  dynamic "ingress_security_rules" {
    for_each = var.gateway_ssh_allowed_cidrs
    content {
      protocol = "6"
      source   = ingress_security_rules.value

      tcp_options {
        min = 22
        max = 22
      }
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    protocol = "17"
    source   = "0.0.0.0/0"

    udp_options {
      min = 51820
      max = 51820
    }
  }

  ingress_security_rules {
    protocol = "17"
    source   = "0.0.0.0/0"

    udp_options {
      min = 21820
      max = 21820
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "tf_public_subnet" {
  compartment_id             = oci_identity_compartment.homelab_tf_compartment.id
  vcn_id                     = oci_core_vcn.homelab_tf_vcn.id
  display_name               = "tf_public_subnet"
  dns_label                  = "tfpubsubnet"
  cidr_block                 = var.oci_public_subnet_cidr_block
  route_table_id             = oci_core_route_table.tf_public_route_table.id
  security_list_ids          = [oci_core_security_list.tf_public_security_list.id]
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_subnet" "tf_private_subnet" {
  compartment_id = oci_identity_compartment.homelab_tf_compartment.id
  vcn_id         = oci_core_vcn.homelab_tf_vcn.id
  display_name   = "tf_private_subnet"
  dns_label      = "tfprivsubnet"
  cidr_block     = var.oci_private_subnet_cidr_block
}

data "oci_identity_availability_domains" "available" {
  compartment_id = var.oci_tenancy_ocid
}

data "oci_core_images" "gateway" {
  compartment_id           = oci_identity_compartment.homelab_tf_compartment.id
  operating_system         = var.gateway_image_operating_system
  operating_system_version = var.gateway_image_operating_system_version
  shape                    = var.gateway_shape

  sort_by    = "TIMECREATED"
  sort_order = "DESC"
}

locals {
  gateway_image_ocid = var.gateway_image_ocid != "" ? var.gateway_image_ocid : data.oci_core_images.gateway.images[0].id
}

resource "oci_core_instance" "gateway" {
  availability_domain = data.oci_identity_availability_domains.available.availability_domains[0].name
  compartment_id      = oci_identity_compartment.homelab_tf_compartment.id
  display_name        = var.gateway_name
  shape               = var.gateway_shape

  shape_config {
    ocpus         = var.gateway_ocpus
    memory_in_gbs = var.gateway_memory_gb
  }

  create_vnic_details {
    assign_public_ip = true
    display_name     = "${var.gateway_name}-vnic"
    hostname_label   = "gateway"
    subnet_id        = oci_core_subnet.tf_public_subnet.id
  }

  metadata = {
    user_data = base64encode(templatefile("${path.module}/cloud_init.yaml.tftpl", {
      gateway_ssh_public_key = var.gateway_ssh_public_key
    }))
  }

  source_details {
    source_id   = local.gateway_image_ocid
    source_type = "image"
  }
}

locals {
  common_tags = [
    "env-prod",
    "managed_by-terraform"
  ]

  use_dhcp = var.ipv4_address == null
}

resource "proxmox_virtual_environment_container" "this" {
  vm_id     = var.vm_id
  tags = concat(local.common_tags, var.tags)
  node_name = var.node_name
  
  unprivileged = var.unprivileged
  features {
    nesting = true
  }
  wait_for_ip {
    ipv4 = true
  }

  initialization {
    hostname = var.name

    ip_config {
      dynamic "ipv4" {
        for_each = local.use_dhcp ? [1] : []
        content {
          address = "dhcp"
        }
      }

      dynamic "ipv4" {
        for_each = local.use_dhcp ? [] : [1]
        content {
          address = var.ipv4_address
          gateway = var.ipv4_gateway
        }
      }
    }
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory_mb
    swap      = var.swap_mb
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.disk_gb
  }

  network_interface {
    name   = "veth0"
    bridge = var.bridge
  }
  
  operating_system {
    template_file_id = var.template_file_id
  }
}

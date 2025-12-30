locals {
  common_tags = [
    "env-prod",
    "managed_by-terraform"
  ]

  use_dhcp = var.ip_address == null
}

resource "proxmox_lxc" "this" {
  vm_id     = var.vm_id
  name      = var.name
  tags = concat(local.common_tags, var.tags)
  node_name = var.node_name
  
  unprivileged = var.unprivileged
  features {
    nesting = true
  }

  initialization {
    hostname = var.name

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.ipv4_gateway
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
    size         = var.disk_size
  }

  network_interface {
    name   = "veth0"
    bridge = var.bridge
  }
  
  operating_system {
    template_file_id = var.template_file
    type = var.os_type
  }
}

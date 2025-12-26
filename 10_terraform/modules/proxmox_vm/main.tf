locals {
  use_dhcp = var.ip_address == null
}

resource "proxmox_virtual_environment_vm" "this" {
  vm_id     = var.vm_id
  name      = var.name
  node_name = var.node_name

  tags = var.tags
  stop_on_destroy = true

  initialization {
    datastore_id      = var.datastore_id
    user_data_file_id = var.cloud_init_file_id

    ip_config {
      ipv4 {
        address = local.use_dhcp ? "dhcp" : var.ip_address
      }
    }
  }

  agent {
    enabled = true
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    datastore_id = var.datastore_id
    import_from  = var.import_disk_id
    interface    = "scsi0"
    size         = var.disk_gb
  }

  network_device {
    bridge = var.bridge
  }

  operating_system {
    type = var.os_type
  }
}

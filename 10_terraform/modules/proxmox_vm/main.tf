locals {
  common_tags = [
    "env-prod",
    "managed_by-terraform"
  ]
  role_tag = "role-${var.ansible_role}"

  tags = concat(
    local.common_tags,
    [local.role_tag]
  )

  use_dhcp = var.ipv4_address == null
}

resource "proxmox_virtual_environment_file" "meta_data" {
  content_type = "snippets"
  datastore_id = var.datastore_id
  node_name    = var.node_name

  source_raw {
    file_name = "${var.name}-meta.yaml"
    data = templatefile(
      "${path.module}/meta_data.tpl",
      {
        hostname = var.name
      }
    )
  }
}

resource "proxmox_virtual_environment_vm" "this" {
  vm_id     = var.vm_id
  name      = var.name
  node_name = var.node_name
  tags      = local.tags

  agent {
    enabled = true
  }

  stop_on_destroy = true

  initialization {
    datastore_id      = var.datastore_id
    user_data_file_id = var.cloud_init_file_id
    meta_data_file_id = proxmox_virtual_environment_file.meta_data.id

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
    type = var.cpu_type
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

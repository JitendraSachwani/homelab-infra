resource "proxmox_virtual_environment_vm" "ci_runner_01" {
  vm_id     = 10002
  name      = "prod-ci-runner-01"

  tags = concat(
    local.common_tags,
    [
      "role-ci"
    ]
  )

  node_name = local.default_node
  initialization {
    datastore_id = local.default_datastore
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  cpu {
    cores = local.default_cpu_cores
  }

  memory {
    dedicated = 4096
  }

  disk {
    import_from  = proxmox_virtual_environment_download_file.ubuntu_22_jammy_qcow2.id
    datastore_id = local.default_datastore
    interface    = "scsi0"
    size         = local.default_disk_gb
  }

  network_device {
    bridge = local.default_bridge
  }

  operating_system {
    type = local.default_os_type
  }
}

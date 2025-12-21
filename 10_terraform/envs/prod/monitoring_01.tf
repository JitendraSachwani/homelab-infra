resource "proxmox_virtual_environment_vm" "monitoring_01" {
  vm_id  = 30001
  name   = "prod-monitoring-01"
  node_name = "pve"

  tags = [
    "env:prod",
    "managed_by:terraform",
    "role:monitoring",
    "template:ubuntu-22",
    "template_version:1"
  ]

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-btrfs"
    size         = 20
    interface    = "scsi0"
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
}

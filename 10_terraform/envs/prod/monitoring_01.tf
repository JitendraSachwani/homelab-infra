resource "proxmox_virtual_environment_vm" "monitoring_01" {
  vm_id  = 30001
  name   = "prod-monitoring-01"
  node_name = "pve"

  clone {
    vm_id = 9001
  }

  tags = [
    "env-prod",
    "managed_by-terraform",
    "role-monitoring",
    "template-ubuntu22",
    "template_version-v1"
  ]

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  disk {
    interface    = "scsi0"
    size         = 20
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

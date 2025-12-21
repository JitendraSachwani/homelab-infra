resource "proxmox_virtual_environment_vm" "monitoring_01" {
  vm_id  = 30001
  name   = "prod-monitoring-01"
  node_name = "pve"

  initialization {
    datastore_id = "local-btrfs"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
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
    import_from  = proxmox_virtual_environment_download_file.latest_ubuntu_22_jammy_qcow2_img.id
    datastore_id = "local-btrfs"
    interface    = "scsi0"
    size         = 20
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

}

resource "proxmox_virtual_environment_download_file" "latest_ubuntu_22_jammy_qcow2_img" {
  content_type = "import"
  datastore_id = "iso-btrfs"
  node_name    = "pve"
  url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  # need to rename the file to *.qcow2 to indicate the actual file format for import
  file_name = "jammy-server-cloudimg-amd64.qcow2"
}

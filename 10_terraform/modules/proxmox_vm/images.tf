resource "proxmox_virtual_environment_download_file" "tmpl_ubuntu_22_jammy_qcow2" {
  content_type = "import"
  datastore_id = "iso-btrfs"
  node_name    = "pve"

  url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  
  # need to rename the file to *.qcow2 to indicate the actual file format for import
  file_name = "tmpl-ubuntu-22-jammy-cloudimg-amd64.qcow2"
}

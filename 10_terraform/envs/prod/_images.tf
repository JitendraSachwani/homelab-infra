resource "proxmox_virtual_environment_download_file" "ubuntu_22_jammy_qcow2" {
  content_type = "import"
  datastore_id = "iso-btrfs"
  node_name    = "pve"

  url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  
  # need to rename the file to *.qcow2 to indicate the actual file format for import
  file_name = "ubuntu-22-jammy-cloudimg-amd64.qcow2"
}

resource "proxmox_virtual_environment_file" "ci_runner_cloud_init" {
  content_type = "snippets"
  datastore_id = local.default_datastore
  node_name    = local.default_node

  source_raw {
    file_name = "prod-ci-runner-01-cloud-init.yaml"
    data = <<-EOF
#cloud-config
hostname: prod-ci-runner-01
timezone: Asia/Kolkata

users:
  - name: iac
    groups: [sudo]
    shell: /bin/bash
    ssh_authorized_keys:
      - ${var.admin_ssh_public_key}
      - ${var.iac_ssh_public_key}
    sudo: ALL=(ALL) NOPASSWD:ALL

package_update: true
packages:
  - qemu-guest-agent
  - curl
  - git
  - ca-certificates

runcmd:
  - systemctl enable --now qemu-guest-agent
  - echo "cloud-init complete" > /var/log/cloud-init.done
EOF
  }
}
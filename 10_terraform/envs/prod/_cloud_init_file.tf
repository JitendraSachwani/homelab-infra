resource "proxmox_virtual_environment_file" "cloud_init_file" {
  content_type = "snippets"
  datastore_id = "local-btrfs"
  node_name    = "pve"

  source_raw {
    file_name = "cloud-init-user-data.yaml"
    data = <<-EOF
#cloud-config
timezone: Asia/Kolkata
manage_etc_hosts: true
ssh_pwauth: false

users:
  - name: iac
    groups: [sudo]
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${var.admin_ssh_public_key}
      - ${var.iac_ssh_public_key}

package_update: true
packages:
  - qemu-guest-agent
  - curl
  - git
  - ca-certificates

runcmd:
  - systemctl enable --now qemu-guest-agent
  - touch /var/lib/cloud/instance/boot-finished
  - echo "cloud-init complete" > /var/log/cloud-init.done
EOF
  }
}

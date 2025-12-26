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

resource "proxmox_virtual_environment_vm" "ci_runner_01" {
  vm_id     = 10101
  name      = "prod-ci-runner-01"
  node_name = local.default_node

  tags = concat(local.common_tags, ["role-ci"])

  stop_on_destroy = true

  initialization {
    datastore_id       = local.default_datastore
    user_data_file_id  = proxmox_virtual_environment_file.ci_runner_cloud_init.id

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  agent {
    enabled = true
  }

  cpu {
    cores = local.default_cpu_cores
  }

  memory {
    dedicated = local.default_memory_mb
  }

  disk {
    datastore_id = local.default_datastore
    import_from  = proxmox_virtual_environment_download_file.ubuntu_22_jammy_qcow2.id
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

output "ansible_hosts" {
  value = {
    ci_runners = {
      "prod-ci-runner-01" = proxmox_virtual_environment_vm.ci_runner_01.ipv4_addresses[1][0]
    }
  }
}

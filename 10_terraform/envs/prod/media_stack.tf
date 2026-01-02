locals {
  media_vms = {
    media_srv_01 = {
      name         = "prod-media-srv-01"
      vm_id        = 50001
      ansible_role = "media_srv"
      ipv4_address = "10.0.5.0/16"
      cores        = 4
      memory_mb    = 3072
    }

    media_mgmt_01 = {
      name         = "prod-media-mgmt-01"
      vm_id        = 50101
      ansible_role = "media_mgmt"
      ipv4_address = "10.0.5.1/16"
      cores        = 2
      memory_mb    = 3072
    }
  }
}

module "media" {
  for_each = local.media_vms

  source = "../../modules/proxmox_vm"
  providers = {
    proxmox = proxmox
  }

  name         = each.value.name
  vm_id        = each.value.vm_id
  ansible_role = each.value.ansible_role

  ipv4_address = each.value.ipv4_address
  ipv4_gateway = "10.0.0.1"

  cores     = each.value.cores
  memory_mb = each.value.memory_mb

  cloud_init_file_id = proxmox_virtual_environment_file.cloud_init_file.id
  import_disk_id     = proxmox_virtual_environment_download_file.ubuntu_22_jammy_qcow2.id
}

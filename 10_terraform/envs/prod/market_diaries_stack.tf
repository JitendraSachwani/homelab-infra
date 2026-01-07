locals {
  market_diaries_vms = {
    media_srv_01 = {
      name         = "prod-market-diaries-storage-01"
      vm_id        = 60001
      ansible_role = "market_diaries_storage"
      ipv4_address = "10.0.6.0/16"
      cores        = 2
      memory_mb    = 2048
      disk_gb      = 20
    }

    media_mgmt_01 = {
      name         = "prod-market-diaries-renderer-01"
      vm_id        = 60101
      ansible_role = "market_diaries_renderer"
      ipv4_address = "10.0.6.1/16"
      cores        = 2
      memory_mb    = 2048
      disk_gb      = 200
    }
  }
}

module "market_diaries" {
  for_each = local.market_diaries_vms

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
  disk_gb   = each.value.disk_gb

  cloud_init_file_id = proxmox_virtual_environment_file.cloud_init_file.id
  import_disk_id     = proxmox_virtual_environment_download_file.ubuntu_22_jammy_qcow2.id
}

module "pihole_01" {
  source = "../../modules/proxmox_lxc"

  providers = {
    proxmox = proxmox
  }

  name  = "prod-pihole-01"
  vm_id = 15301
  ansible_role  = "pihole"
  
  ipv4_address = "10.0.1.53/16"
  ipv4_gateway = "10.0.0.1"

  template_file_id = "iso-btrfs:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
  
  cores = 1
  memory_mb = 512
}

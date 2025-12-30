module "pihole_01" {
  source = "../../modules/proxmox_lxc"

  providers = {
    proxmox = proxmox
  }

  name  = "prod-pihole-01"
  vm_id = 15301
  tags = ["role-pihole"]
  
  ipv4_address = "10.0.1.53/16"
  ipv4_gateway = "10.0.0.1"

  template_file_id = proxmox_virtual_environment_download_file.ubuntu_22_jammy_lxc_img.id
  
  cores = 1
  memory_mb = 512
}

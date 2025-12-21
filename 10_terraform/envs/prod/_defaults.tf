locals {
  env = "prod"

  default_node      = "pve"
  default_bridge    = "vmbr0"
  default_datastore = "local-btrfs"

  default_cpu_cores = 2
  default_memory_mb = 2048
  default_disk_gb   = 20

  default_os_type = "l26"

  common_tags = [
    "env-prod",
    "managed_by-terraform"
  ]
}

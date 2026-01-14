terraform {
  required_version = ">= 1.14.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.46"
    }

    oci = {
      source  = "oracle/oci"
      version = ">=4.67.3"
    }
  }
}

provider "oci" {
  user_ocid        = var.oci_user_ocid
  fingerprint      = var.oci_fingerprint
  tenancy_ocid     = var.oci_tenancy_ocid
  private_key_path = "../../../keys/oci_rsa_key.pem"
  region           = "ap-mumbai-1"
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password

  insecure = true
}

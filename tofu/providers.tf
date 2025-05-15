terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.78.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://hosting.srv.lly.sh:8006/api2/json"
  insecure = true # allow self-signed certificate
  username = var.proxmox_user
  password = var.proxmox_password
}


terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.80.0"
    }
    desec = {
      source  = "valodim/desec"
      version = "0.6.1"
    }
    zonefile = {
      source  = "ahamlinman/zonefile"
      version = "0.1.2"
    }
  }
}

provider "proxmox" {
  endpoint = "https://hosting.srv.lly.sh:8006/api2/json"
  insecure = true # allow self-signed certificate
  username = var.proxmox_user
  password = var.proxmox_password
}

provider "desec" {
  api_token = var.desec_token
}


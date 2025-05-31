variable "proxmox_user" {
  description = "username for proxmox authentication"
  default     = "tofu@pve"
}

variable "proxmox_password" {
  description = "password for proxmox authentication"
  sensitive   = true
}

variable "desec_token" {
  description = "Auth-Token for desec.io"
  sensitive   = true
}

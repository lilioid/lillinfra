variable "proxmox_user" {
  description = "username for proxmox authentication"
  default     = "tofu@pve"
}

variable "proxmox_password" {
  description = "password for proxmox authentication"
  sensitive   = true
}

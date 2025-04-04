variable "tenants" {
  description = "List of tenants which have stuff running on my proxmox server"
  type = list(object({
    name = string
    id   = number
    vms = list(number)
  }))
}


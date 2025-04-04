# resource "proxmox_virtual_environment_network_linux_bridge" "tenantBridge" {
#   for_each = { for i in var.tenants: i.name => i }

#   node_name = "pve"
#   name      = "vmbr${each.value.id}"
#   comment   = "Network for ${each.value.name}s VMs"
# }


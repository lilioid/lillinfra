resource "proxmox_virtual_environment_group" "tenants" {
  group_id = "tenants"

  acl {
    path = "/storage/local"
    role_id = "PVEDatastoreUser"
    propagate = true
  }
}

resource "proxmox_virtual_environment_user" "tenant-users" {
  for_each = { for i in var.tenants : i.name => i }

  user_id = "${each.value.name}@pve"
  groups = [
    resource.proxmox_virtual_environment_group.tenants.group_id
  ]

  dynamic "acl" {
    for_each = each.value.vms
    content {
      path = "/vms/${acl.value}"
      propagate = true
      role_id = "PVEVMUser"
    }
  }

  lifecycle {
    ignore_changes = [ password, keys ]
  }
}


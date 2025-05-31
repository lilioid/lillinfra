data "zonefile_record_sets" "zone" {
  origin = replace(basename(var.zonefile_path), ".zone", "")
  content = file(var.zonefile_path)
}

resource "desec_domain" "domain" {
  name = data.zonefile_record_sets.zone.origin
}

resource "desec_rrset" "records" {
  for_each = { for i in data.zonefile_record_sets.zone.rrsets : "${i.name != null ? i.name : "@"} ${i.type}" => i }
  domain = desec_domain.domain.name
  subname = each.value.name != null ? each.value.name : ""
  type = each.value.type
  ttl = each.value.ttl
  records = toset(each.value.data)
}

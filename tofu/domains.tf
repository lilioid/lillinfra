module "desec_domain_config" {
  for_each = fileset("${path.root}/../data/dns", "*.zone")
  source = "./desec_domain_config"
  zonefile_path = "${path.root}/../data/dns/${each.key}"
}

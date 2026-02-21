resource "hcloud_network" "private_network" {
  name     = var.private_network_name
  ip_range = var.private_network_ip_range
}

resource "hcloud_network_subnet" "private_network_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.private_network.id
  network_zone = var.network_zone
  ip_range     = var.private_network_subnet_range
}


resource "tailscale_acl" "nat_gateway_acl" {
  overwrite_existing_content = true
  acl = jsonencode({
    tagOwners     = { "tag:gateway" = ["autogroup:admin"] }
    autoApprovers = { routes = { (var.private_network_subnet_range) = ["tag:gateway"] } }
    acls          = [{ action = "accept", src = ["autogroup:admin"], dst = ["*:*"] }]
  })
}

resource "tailscale_tailnet_key" "nat_gateway_key" {
  description         = "nat-gateway bootstrap key"
  preauthorized       = true
  ephemeral           = true
  expiry              = 3600
  reusable            = false
  tags                = ["tag:gateway"]
  depends_on          = [tailscale_acl.nat_gateway_acl]
}

resource "tailscale_dns_split_nameservers" "cluster_internal" {
  domain      = var.split_dns_domain
  nameservers = [local.nat_ip]
  depends_on  = [tailscale_acl.nat_gateway_acl]
}

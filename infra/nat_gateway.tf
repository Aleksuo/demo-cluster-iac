locals {
  nat_ip                       = cidrhost(var.private_network_subnet_range, 20)
  split_dns_wildcard_target_ip = local.lb_ip
}

resource "hcloud_server" "nat_gateway" {
  name        = "${var.cluster_name}-nat-gateway"
  image       = "ubuntu-24.04"
  server_type = "cx23"
  location    = var.location

  firewall_ids = [hcloud_firewall.nat_gateway_firewall.id]

  network {
    network_id = hcloud_network.private_network.id
    ip         = local.nat_ip
  }

  user_data = templatefile("${path.module}/cloud-init/nat-gateway.yaml.tftpl", {
    private_network_subnet_range = var.private_network_subnet_range
    tailscale_auth_key           = tailscale_tailnet_key.nat_gateway_key.key
    nat_gateway_private_ip       = local.nat_ip
    split_dns_domain             = var.split_dns_domain
    split_dns_wildcard_target_ip = local.split_dns_wildcard_target_ip
  })

  depends_on = [tailscale_acl.nat_gateway_acl]
}

resource "hcloud_network_route" "default_via_nat" {
  network_id  = hcloud_network.private_network.id
  destination = "0.0.0.0/0"
  gateway     = local.nat_ip
  depends_on  = [hcloud_server.nat_gateway]
}

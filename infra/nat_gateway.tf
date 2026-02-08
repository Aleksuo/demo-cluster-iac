locals {
  nat_ip = cidrhost(var.private_network_subnet_range, 20)
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
  })

  depends_on = [tailscale_acl.nat_gateway_acl]
}

resource "hcloud_network_route" "default_via_nat" {
  network_id  = hcloud_network.private_network.id
  destination = "0.0.0.0/0"
  gateway     = local.nat_ip
  depends_on  = [hcloud_server.nat_gateway]
}
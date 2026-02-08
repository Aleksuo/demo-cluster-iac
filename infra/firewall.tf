resource "hcloud_firewall" "nat_gateway_firewall" {
  name = "${var.cluster_name}-nat-gateway"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "any"
    source_ips = [var.private_network_subnet_range]
  }

  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "any"
    source_ips = [var.private_network_subnet_range]
  }
}
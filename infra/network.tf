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


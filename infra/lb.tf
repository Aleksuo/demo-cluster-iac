locals {
  lb_ip = cidrhost(var.private_network_subnet_range, 10)
}

resource "hcloud_load_balancer" "controlplane_load_balancer" {
  name               = "talos-lb"
  load_balancer_type = var.load_balancer_type
  location           = var.location
}

resource "hcloud_load_balancer_network" "srvnetwork" {
  load_balancer_id        = hcloud_load_balancer.controlplane_load_balancer.id
  network_id              = hcloud_network.private_network.id
  enable_public_interface = false
  ip                      = local.lb_ip
}

resource "hcloud_load_balancer_target" "control_plane_target" {
  type             = "server"
  load_balancer_id = hcloud_load_balancer.controlplane_load_balancer.id
  server_id        = hcloud_server.controlplane_server.id
  use_private_ip   = true
  depends_on = [
    hcloud_load_balancer_network.srvnetwork,
    hcloud_network_subnet.private_network_subnet,
    hcloud_server.controlplane_server
  ]
}

resource "hcloud_load_balancer_service" "controlplane_load_balancer_service_kubectl" {
  load_balancer_id = hcloud_load_balancer.controlplane_load_balancer.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
}

resource "hcloud_load_balancer_service" "controlplane_load_balancer_service_talosctl" {
  load_balancer_id = hcloud_load_balancer.controlplane_load_balancer.id
  protocol         = "tcp"
  listen_port      = 50000
  destination_port = 50000
}



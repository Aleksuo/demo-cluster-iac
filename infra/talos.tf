locals {
  cp_ip = tolist(hcloud_server.controlplane_server.network)[0].ip
  worker_ips = [
    for s in values(hcloud_server.worker_server) : tolist(s.network)[0].ip
  ]
  talos_nodes = concat([local.cp_ip], local.worker_ips)
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version_contract
}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${hcloud_load_balancer_network.srvnetwork.ip}:6443"
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version_contract
  kubernetes_version = var.kubernetes_version
  config_patches = [templatefile("${path.module}/templates/controlplanepatch.yaml.tmpl", {
    loadbalancerip      = hcloud_load_balancer_network.srvnetwork.ip,
    subnet              = var.private_network_subnet_range,
    pod_subnet_cidr     = var.pod_subnet_cidr,
    service_subnet_cidr = var.service_subnet_cidr
    })
  ]
  depends_on = [
    hcloud_load_balancer_network.srvnetwork
  ]
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [local.lb_ip]
  nodes                = [local.cp_ip]
}

resource "hcloud_server" "controlplane_server" {
  name        = "talos-controlplane"
  image       = var.image_id
  server_type = var.controlplane_type
  location    = var.location
  labels      = { type = "talos-controlplane" }
  user_data   = data.talos_machine_configuration.controlplane.machine_configuration
  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }
  network {
    network_id = hcloud_network.private_network.id
  }
  depends_on = [
    hcloud_network_route.default_via_nat,
    hcloud_network_subnet.private_network_subnet,
    hcloud_load_balancer.controlplane_load_balancer,
    talos_machine_secrets.this
  ]
}

resource "talos_machine_bootstrap" "bootstrap" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = local.cp_ip
  node                 = local.cp_ip
  depends_on           = [hcloud_server.controlplane_server]
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${hcloud_load_balancer_network.srvnetwork.ip}:6443"
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version_contract
  kubernetes_version = var.kubernetes_version
  config_patches = [
    templatefile("${path.module}/templates/workerpatch.yaml.tmpl", {
      subnet              = var.private_network_subnet_range
      pod_subnet_cidr     = var.pod_subnet_cidr,
      service_subnet_cidr = var.service_subnet_cidr
    })
  ]
  depends_on = [
    hcloud_load_balancer_network.srvnetwork
  ]
}


resource "hcloud_server" "worker_server" {
  for_each    = var.workers
  name        = each.value.name
  image       = var.image_id
  server_type = each.value.server_type
  location    = each.value.location
  labels      = { type = "talos-worker" }
  user_data   = data.talos_machine_configuration.worker.machine_configuration
  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }
  network {
    network_id = hcloud_network.private_network.id
  }
  depends_on = [
    hcloud_network_subnet.private_network_subnet,
    hcloud_load_balancer.controlplane_load_balancer,
  hcloud_server.controlplane_server]
}

data "talos_client_configuration" "all" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [local.lb_ip]
  nodes                = local.talos_nodes
}


resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.cp_ip
}
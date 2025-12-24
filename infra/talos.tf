resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version_contract
}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${hcloud_load_balancer.controlplane_load_balancer.ipv4}:6443"
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version_contract
  kubernetes_version = var.kubernetes_version
  config_patches = [templatefile("${path.module}/templates/controlplanepatch.yaml.tmpl", {
    loadbalancerip = hcloud_load_balancer.controlplane_load_balancer.ipv4, subnet = var.private_network_subnet_range
    })
  ]
  depends_on = [
    hcloud_load_balancer.controlplane_load_balancer
  ]
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints = [
    hcloud_load_balancer.controlplane_load_balancer.ipv4
  ]
  nodes = [ hcloud_load_balancer.controlplane_load_balancer.ipv4 ]
}

resource "hcloud_server" "controlplane_server" {
  name        = "talos-controlplane"
  image       = var.image_id
  server_type = var.controlplane_type
  location    = var.location
  labels      = { type = "talos-controlplane" }
  user_data   = data.talos_machine_configuration.controlplane.machine_configuration
  network {
    network_id = hcloud_network.private_network.id
    ip         = var.controlplane_ip
  }
  depends_on = [
    hcloud_network_subnet.private_network_subnet,
    hcloud_load_balancer.controlplane_load_balancer,
    talos_machine_secrets.this
  ]
}

resource "talos_machine_bootstrap" "bootstrap" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = hcloud_server.controlplane_server.ipv4_address
  node                 = hcloud_server.controlplane_server.ipv4_address
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${hcloud_load_balancer.controlplane_load_balancer.ipv4}:6443"
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version_contract
  kubernetes_version = var.kubernetes_version
  config_patches = [
    templatefile("${path.module}/templates/workerpatch.yaml.tmpl", {
      subnet = var.private_network_subnet_range
    })
  ]
  depends_on = [
    hcloud_load_balancer.controlplane_load_balancer
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
  network {
    network_id = hcloud_network.private_network.id
  }
  depends_on = [hcloud_network_subnet.private_network_subnet, hcloud_load_balancer.controlplane_load_balancer, hcloud_server.controlplane_server]
}


resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = hcloud_server.controlplane_server.ipv4_address
}
terraform {
  required_providers {
    hcloud = {
        source = "hetznercloud/hcloud"
        version = "1.45.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_network" "private_network" {
    name = "k3s-cluster"
    ip_range = "10.0.0.0/16" 
}

resource "hcloud_network_subnet" "private_network_subnet" {
    type = "cloud"
    network_id = hcloud_network.private_network.id
    network_zone = "eu-central"
    ip_range = "10.0.1.0/24"   
}
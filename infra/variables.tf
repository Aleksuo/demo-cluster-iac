variable "image_id" {
  description = "The id of the saved talos snapshot in hetzner"
  type        = string
  default     = "343755526"
}

variable "cluster_name" {
  description = "Name for the cluster"
  type        = string
  default     = "talos-hcloud-cluster"
}


variable "talos_version_contract" {
  type    = string
  default = "v1.11"
}

variable "kubernetes_version" {
  type    = string
  default = "1.34.2"
}

# controlplane
variable "controlplane_type" {
  default = "cx23"
}

variable "controlplane_ip" {
  default = "10.0.0.3"
}

# network
variable "private_network_name" {
  default = "talos-network"
}

variable "private_network_ip_range" {
  default = "10.0.0.0/16"
}

variable "private_network_subnet_range" {
  default = "10.0.0.0/24"
}

# lb
variable "network_zone" {
  default = "eu-central"
}

variable "load_balancer_type" {
  default = "lb11"
}


variable "location" {
  default = "hel1"
}

variable "workers" {
  default = {
    1 = {
      server_type = "cx23",
      name        = "talos-worker-1",
      location    = "hel1",
      taints      = []
    }
  }
}

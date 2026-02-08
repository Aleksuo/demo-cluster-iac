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

variable "controlplane_type" {
  default = "cx23"
}

variable "private_network_name" {
  default = "talos-network"
}

variable "private_network_ip_range" {
  default = "172.20.0.0/16"
}

variable "private_network_subnet_range" {
  default = "172.20.0.0/22"
}

variable "pod_subnet_cidr" {
  default = "10.240.0.0/16"
}

variable "service_subnet_cidr" {
  default = "10.241.0.0/16"
}


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

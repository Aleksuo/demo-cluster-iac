resource "hcloud_primary_ip" "master_node_public_ip" {
  name = "master_primary_ip"
  datacenter = "hel1-dc2"
  type = "ipv4"
  assignee_type = "server"
  auto_delete = true
}

data "template_file" "master-node-config" {
    template = file("${path.module}/config/cloud-init-master.yaml")
    vars = {
      local_ssh_public_key = file("${path.module}/.ssh/local_ssh.pub")
      local_ssh_public_key_2 = file("${path.module}/.ssh/local_ssh2.pub")
      worker_ssh_public_key = tls_private_key.worker-ssh-key.public_key_openssh
      hcloud_token = var.hcloud_token
      hcloud_network = hcloud_network.private_network.id
      public_ip = tostring(hcloud_primary_ip.master_node_public_ip.ip_address)
    }
}

resource "hcloud_server" "master-node" {
    name = "master-node"
    image = "ubuntu-24.04"
    server_type = "cax11"
    location = "hel1"
    public_net {
      ipv4 = hcloud_primary_ip.master_node_public_ip.id
      ipv4_enabled = true
      ipv6_enabled = true
    }
    network {
      network_id = hcloud_network.private_network.id
      ip = "10.0.1.1"
    }
    user_data = data.template_file.master-node-config.rendered

    depends_on = [ hcloud_network_subnet.private_network_subnet ]
}

output "master_node_public_ip" {
  value = tostring(hcloud_primary_ip.master_node_public_ip.ip_address)
}
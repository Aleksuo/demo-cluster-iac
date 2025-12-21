resource "tls_private_key" "worker-ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
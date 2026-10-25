output "hosts" {
  description = "The hostname of the servers to test env-setup."
  value = {
    macos = var.hosts.macos ? {
      id   = module.macos[0].id
      name = module.macos[0].public_dns
      user = "ec2-user"
      key  = "${path.module}/dist/id_rsa"
    } : null
    linux = var.hosts.linux ? {
      id   = module.linux[0].id
      name = module.linux[0].public_dns
      user = "ubuntu"
      key  = "${path.module}/dist/id_rsa"
    } : null
  }
}

output "ssh_prv_key" {
  description = "The SSH private key to connect to the test servers."
  value       = module.keys.private_key_pem
  sensitive   = true
}

output "ssh_pub_key" {
  description = "The SSH public key to connect to the test servers."
  value       = module.keys.public_key_openssh
}

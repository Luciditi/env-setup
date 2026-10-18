module "keys" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name           = local.stack_name
  create_private_key = true
}

resource "local_file" "prv_key" {
  content  = module.keys.private_key_pem
  filename = "${path.module}/dist/id_rsa"

  provisioner "local-exec" {
    command = "chmod 600 ${path.module}/dist/id_rsa"
  }
}

resource "local_file" "pub_key" {
  content  = module.keys.public_key_openssh
  filename = "${path.module}/dist/id_rsa.pub"
}

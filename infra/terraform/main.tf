module "linux" {
  source = "terraform-aws-modules/ec2-instance/aws"
  count  = var.hosts.linux ? 1 : 0

  name                   = "${local.stack_name}-linux"
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.xlarge"
  key_name               = module.keys.key_pair_name
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.ssh_access.id]
  subnet_id              = data.aws_subnet.default.id

  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      volume_size = 30
    },
  ]
}

module "macos" {
  source = "terraform-aws-modules/ec2-instance/aws"
  count  = var.hosts.macos ? 1 : 0

  name                   = "${local.stack_name}-macos"
  ami                    = data.aws_ami.macos.id
  instance_type          = "mac2.metal"
  key_name               = module.keys.key_pair_name
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.ssh_access.id]
  subnet_id              = data.aws_subnet.default.id
  tenancy                = "host"
  host_id                = aws_ec2_host.dedicated[0].id
}

resource "aws_ec2_host" "dedicated" {
  count = var.hosts.macos ? 1 : 0

  auto_placement    = "on"
  availability_zone = data.aws_subnet.default.availability_zone
  host_recovery     = "off"
  instance_type     = "mac2.metal"
}

resource "aws_security_group" "ssh_access" {
  name        = "${local.stack_name}-ssh"
  description = "SSH for localhost that provisioned ${local.stack_name}"

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.http.ip.response_body}/32"]
  }

}

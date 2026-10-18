data "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnets" "defaults" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "default" {
  id = data.aws_subnets.defaults.ids[local.default_subnet]
}

data "http" "ip" {
  url = "https://api.ipify.org"
}

data "aws_ami" "ubuntu" {
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


data "aws_ami" "macos" {
  owners      = ["628277914472"]
  most_recent = true

  filter {
    name   = "architecture"
    values = ["arm64_mac"]
  }

  filter {
    name   = "description"
    values = ["*${var.macos_version}*"]
  }

  filter {
    name   = "name"
    values = ["amzn-ec2-macos-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

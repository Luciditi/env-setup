<!-- BEGIN_TF_DOCS -->
# env-setup test infra

A Terraform module for test infrastructure to run env-setup against.

It will build the following:
- An EC2 security group in the default VPC.
- A SSH key pair to enable SSH
- An EC2 key pair to SSH into the EC2 hosts.
- A couple of EC2 hosts placed in the default VPC subnet:
    - A Ubuntu EC2 host.
    - A macOS EC2 host.

## test scripts
The `scripts` directory has a few scripts to test the built infrastructure:

- [scripts/env-setup](scripts/env-setup): test the [env-setup script](../../scripts/env-setup).
- [scripts/init](scripts/init): test the [init script](../../scripts/init).
- [scripts/macos-ard-connect](scripts/macos-ard-connect): connect to the macos GUI via VNC.
- [scripts/macos-ard-enable](scripts/macos-ard-enable): enable Apple Remote Desktop on the macos host.
- [scripts/macos-ard-ssh](scripts/macos-ard-ssh): setup an SSH/ARD tunnel.
- [scripts/ssh](scripts/ssh): ssh into the infra.
- [scripts/sudo-pass](scripts/sudo-pass): set the sudo pass on the infra.

### linux
After running `terraform apply` you can run these commands to test env-setup on a linux EC2 host:
```
# set the sudo pass
./scripts/sudo-pass linux

# test the init script that's hosted on https://example.com/env-setup
./scripts/init linux https://example.com/env-setup

# run/setup env-setup with an interactive prompt for the playbook
./scripts/env-setup linux

# run 01-config env-setup playbook
./scripts/env-setup linux 01-config
```

### macos
After running `terraform apply` you can run these commands to test env-setup on a macOS EC2 host with some caveats:

- the `./scripts/macos-ard-ssh` command needs to be run in another terminal window as this will keep an SSH session open
  - this session is used to connect an Apple Remote Desktop (ARD) session
- you may need to run `env-setup` on a terminal session in the ARD window; Apple prevents some operations from happening directly through SSH.
```
# set the sudo pass
./scripts/sudo-pass linux

# enable ARD for the macos host
./scripts/macos-ard-enable

# in separate terminal, keep an SSH connection for ARD-tunneling
./scripts/macos-ard-ssh

# open a VNC session to the macos GUI
./scripts/macos-ard-connect

# test the init script that's hosted on https://example.com/env-setup
./scripts/init macos https://example.com/env-setup

# run/setup env-setup with an interactive prompt for the playbook
./scripts/env-setup macos

# run 01-config env-setup playbook
./scripts/env-setup macos 01-config
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.4 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.94.1 |
| <a name="provider_http"></a> [http](#provider\_http) | 3.4.5 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.5.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_keys"></a> [keys](#module\_keys) | terraform-aws-modules/key-pair/aws | ~> 2.0 |
| <a name="module_linux"></a> [linux](#module\_linux) | terraform-aws-modules/ec2-instance/aws | ~> 5.7 |
| <a name="module_macos"></a> [macos](#module\_macos) | terraform-aws-modules/ec2-instance/aws | ~> 5.7 |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_host.dedicated](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_host) | resource |
| [aws_security_group.ssh_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [local_file.prv_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.pub_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [aws_ami.macos](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_subnet.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnets.defaults](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [http_http.ip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_AWS_ACCESS_KEY_IAM"></a> [AWS\_ACCESS\_KEY\_IAM](#input\_AWS\_ACCESS\_KEY\_IAM) | The AWS access key for admin role auth. | `string` | n/a | yes |
| <a name="input_AWS_ADMIN_ARN"></a> [AWS\_ADMIN\_ARN](#input\_AWS\_ADMIN\_ARN) | The AWS ARN of admin role. | `string` | n/a | yes |
| <a name="input_AWS_SECRET_KEY_IAM"></a> [AWS\_SECRET\_KEY\_IAM](#input\_AWS\_SECRET\_KEY\_IAM) | The AWS secret key for admin role auth. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment prefix string for the AWS resources. | `string` | `"temp"` | no |
| <a name="input_hosts"></a> [hosts](#input\_hosts) | The list of hosts to enable for testing. | `map(bool)` | <pre>{<br>  "linux": true,<br>  "macos": true<br>}</pre> | no |
| <a name="input_macos_version"></a> [macos\_version](#input\_macos\_version) | The version of macos to test on. | `string` | `"Sonoma"` | no |
| <a name="input_name"></a> [name](#input\_name) | The unique name for the AWS resources. | `string` | `"env-setup"` | no |
| <a name="input_region"></a> [region](#input\_region) | The default AWS region for AWS resources. | `string` | `"us-east-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_hosts"></a> [hosts](#output\_hosts) | The hostname of the servers to test env-setup. |
| <a name="output_ssh_prv_key"></a> [ssh\_prv\_key](#output\_ssh\_prv\_key) | The SSH private key to connect to the test servers. |
| <a name="output_ssh_pub_key"></a> [ssh\_pub\_key](#output\_ssh\_pub\_key) | The SSH public key to connect to the test servers. |

# Prerequisites
This module is dependent on a few things:

- IAM creds/role used in the `var.AWS_*` vars to build the resources.

# Notes
- The test instance for macOS is using physical infra on EC2 which comes with a little more limitations than VM instances. See the [AWS developer documenation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-mac-instances.html#mac-instance-considerations) for noted differences between standard EC2 instances.
<!-- END_TF_DOCS -->
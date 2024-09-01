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

- [scripts/env-setup](scripts/env-setup): test the [env-setup script](../scripts/env-setup).
- [scripts/init](scripts/init): test the [init script](../scripts/init).
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


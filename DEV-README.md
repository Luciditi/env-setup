# Development
This repo is designed to be forked/extended/reused to fit a user or 
organization's environment setup needs.

If you want to create your own variant, you can fork this repo, and then alter 
the `scripts/init` and `*.yml` config files to point your own repo URLs.

## Design
There isn't much to env-setup. To use one sentence, it's a text user interface 
for Git, Ansible, & Homebrew to install/configure your macOS / Linux 
environment.

If you want to do development, see the summary/notes on each of its 
components below. 

### Ansible Playbooks
The `ansible` [directory](ansible) contains all the playbooks that will run in either the 
macOS / Linux environment. Both sets of playbooks re-use the same manifest 
variables in `*.yml` but run the task in different ways. For example, Homebrew's 
[Cask system](https://github.com/Homebrew/homebrew-cask) for app delivery 
doesn't work in a Linux environment, so a variable map attempts to find the 
closest app that might be available for the package manager.

Most playbooks share the same config file symlinked from the `.00-init` 
playbook so they only need to be edited once.

The `.00-init` playbook is designed to be an initial startup playbook that 
should only run once (a `.init` file is placed here as marker to note this). 
All other playbooks can be ran multiple times as needed by user.

### Docker
The `docker` [directory](infra/docker) is a configuration directory for building an 
Ubuntu linux image with `env-setup` installed. Additional configuration files 
are included. 

### Router
The `router` [directory](infra/router) is a [Hono](https://hono.dev/) URL router that delivers 
a init bash script when `https://example.com/env-setup` is requested in a 
`curl` command. 

The router uses TypeScript/Hono and can be tested locally with Cloudflare 
[Wranger](https://developers.cloudflare.com/workers/wrangler/) and run live 
with [Workers](https://developers.cloudflare.com/workers/). It assumes this 
repo is hosted on GitHub so alterative Git hosting might will need changes.

It's a bit overengineered, but it enables possible dyanmic script generation 
in the future. 

This is an optional component for script delivery; nothing prevents you from 
placing a static script on a web server as an alternative here to delivery the 
[init script](scripts/init).

### Scripts
The `scripts` [directory](scripts) is the "front end" here. Everything is written in bash 
and will work in either a macOS / Linux environment. The scripts are mostly 
logic to confirm Git is setup (to deliver `env-setup`) and Ansible is ready to 
run. After thatt, the user can then select their config & Ansible playbook 
to run when needed.

If you need to troubleshoot issues with `env-setup`, running `env-setup -v` will
run the bash scripting & Ansible playbook with the verbose flag. If you need 
to do further debugging with the playbook tasks, refer to the Ansible 
docs on [debugging playbooks](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_debugger.html).

## Testing & Quality Gates

`env-setup` includes a comprehensive automated test harness and multi-layer quality gates.

### Bats Test Suite

The test suite in [`tests/`](tests) uses [Bats](https://github.com/bats-core/bats-core) to test CLI dispatch, configuration resolution, regressions, VM subcommands, formula intersection, and config export:

```bash
bats tests/
```

### Linters & Pre-Commit

All shell scripts, YAML files, and Ansible playbooks are verified with pre-commit hooks:

```bash
pre-commit run --all-files
```

Individual checks:
- **ShellCheck**: `shellcheck -x scripts/env-setup scripts/_vm scripts/_remote scripts/vm/* infra/terraform/scripts/*`
- **YAML Lint**: `yamllint -c .yamllint.yml .github/workflows/*.yml *.config.yml`
- **Ansible Lint**: `ansible-lint`

### Local VM Testing (Tart)

Local macOS and Linux VM testing uses [Tart](https://tart.run/) and the `env-setup vm` subcommands:

- `env-setup vm warm [name]`: Pre-installs the warm package intersection and Galaxy requirements in a VM.
- `env-setup vm test [macos|linux] [target]`: Clones an ephemeral Copy-on-Write VM (`es-test-*`), executes playbooks or bootstrap `init`, asserts idempotency (`changed == 0`), and automatically tears down the VM upon completion.

### Base Image & Package Intersection

The Linux container builds use a pre-warmed base container artifact:
- `scripts/formula-intersection`: Computes common Homebrew packages across configuration presets (`.mini`, `default`, `.most`).
- `infra/docker/Dockerfile.base`: Pre-builds and caches the warm base with Ubuntu 24.04, Linuxbrew, Galaxy roles, and common formulae.
- `infra/docker/Dockerfile`: Inherits from `Dockerfile.base`, reducing matrix build times in CI.

### Remote VM Testing (Terraform)

The `infra/terraform` [directory](infra/terraform) contains a Terraform module to provision EC2 instances (Ubuntu 24.04 and macOS) for remote AWS validation. Use the [scripts](infra/terraform/scripts) to run tests against remote AWS instances.

# env-setup
[![Lint](https://github.com/Luciditi/env-setup/actions/workflows/lint.yml/badge.svg)](https://github.com/Luciditi/env-setup/actions/workflows/lint.yml)
[![Deploy Image](https://github.com/Luciditi/env-setup/actions/workflows/deploy-image.yml/badge.svg)](https://github.com/Luciditi/env-setup/actions/workflows/deploy-image.yml)
[![Terraform](https://github.com/Luciditi/env-setup/actions/workflows/tf.yml/badge.svg)](https://github.com/Luciditi/env-setup/actions/workflows/tf.yml)

<img align="right" width="250" src="https://github.com/Luciditi/env-setup/assets/1087111/7ad0d467-384e-483c-8dcd-b63c19d90c3e">

`env-setup` is a workstation provisioner for macOS or Linux. It uses [Ansible](https://www.ansible.com/) and [Homebrew](https://brew.sh/).

## Quickstart

1. Install the tool: `bash <(curl -sL jig.io/env-setup)` 
    - Or use [Homebrew](https://brew.sh/): `brew install luciditi/tap/env-setup`.
2. Set the configuration: `env-setup -c` 
    - `none`: Use an **empty** configuration.
    - `mini`: Use a **minimum** configuration.
    - `default`: Use a **workable default** configuration.
    - `most`: Use **all** features.
    - `custom`: Create a **new** `config.yml` configuration. Edit this configuration with `env-setup -e`.
3. Run the tool: `env-setup`

## Usage

<img align="right" width="250" src="https://github.com/Luciditi/env-setup/assets/1087111/0e6b5b99-477c-49df-b6f3-42e908dffa8a">

### Init

The initialize command makes sure that you have `git` and an SSH key to download this repository. It installs the tool in your home directory under `env-setup`.

If you do not have an SSH key, add a new SSH key in [GitHub](https://github.com/settings/keys).
<br /><br /><br /><br /><br /><br /><br />

<img align="right" width="250" src="https://github.com/Luciditi/env-setup/assets/1087111/4abc41e2-79b0-4f11-9504-ce9221852d83">

### Config

The configuration YAML file (`config.yml`) contains a **manifest** of Ansible _variables_. These variables set **what the system installs in your environment**.

`env-setup` has five starter configuration templates:
  - `none`: The tool gives no environment setup. It keeps the `env-setup` tool for later use.
  - `mini`: The tool gives basic features (scripts, Homebrew, and Ansible).
  - `default`: The tool gives a **workable default** environment setup.
  - `most`: The tool gives **all** features for a complete environment setup.
  - `custom`: You specify a **custom** `config.yml` configuration. Read this [example config.yml](https://gist.github.com/ShawnConn/2400705e601d6315394f0e4f01bb66b8).

Change the values in `config.yml` to match the needs of your environment setup. If you must manually update a `custom` configuration, run `env-setup -e` to edit the file.

### Export

You can export your existing machine configuration into a reusable `config.export.yml` manifest by running `env-setup export`:

```bash
env-setup export                # Exports current state to config.export.yml
env-setup export my-config.yml  # Exports current state to custom file path
```

The export playbook inspects installed Homebrew taps, formulae, casks, Mac App Store apps, VS Code extensions, Cargo packages, and Git repositories.

<img align="right" width="250" src="https://github.com/Luciditi/env-setup/assets/1087111/7d30e859-b7c6-4f21-b35d-879ae550a4f7">

### Run

When you run `env-setup` for the first time, it makes sure that you have Ansible. Then, it prompts you to select an Ansible _playbook_.

To specify a playbook, run the command with the playbook name. To run the configuration playbook, run `env-setup 01-config`. To run all playbooks in sequence, run `env-setup all`.
<br /><br /><br /><br /><br /><br /><br />

### Updating

Run `env-setup -u` to update the installed repository and the installed [dotfiles repository](https://github.com/Luciditi/env-setup-dotfiles).

### Playbooks

An Ansible _playbook_ is a series of _tasks_. The tasks run to build your setup. `env-setup` has 8 main playbooks and other optional playbooks.

- `01-config`: Configures your [dotfiles](https://dotfiles.github.io/) for your app and CLI configuration. It defaults to [env-setup-dotfiles](https://github.com/Luciditi/env-setup-dotfiles) when not overridden.
- `02-cli`: Installs CLI tools with [Homebrew formulas](https://formulae.brew.sh/formula/).
- `03-apps`: Installs GUI applications with [Homebrew casks](https://formulae.brew.sh/cask/). It also uses the Linux package manager and the App Store via [mas](https://github.com/mas-cli/mas).
- `04-packages`: Installs common programming language dependencies for development tooling. It supports Go, Node, PHP, Ruby, Rust, and Python.
- `05-repos`: Clones Git repositories for active development projects or reference vendors.
- `06-os`: Configures the OS settings.
- `07-cloud`: Configures the host for cloud file sync.
- `08-prefs`: Configures other app settings.

To add other playbooks, read the **Custom Playbook** section.

### Task Info

To see a list of tasks in a playbook, run `env-setup -i` with the playbook name. For example, run `env-setup -i 03-apps`.

The tool prints an ordered task list. The list contains a description and tags for each task in the playbook.

### Skipping Tasks

Each task has associated tags.

To select tags, use the `-t` option. To skip tags, use the `-s` option. To specify multiple tags, separate them with a comma.

For example:
- To install only **Node and Python** packages, run `env-setup -t node,python 04-packages`.
- To install all packages except **PHP** packages, run `env-setup -s php 04-packages`.

### Environment Variable Overrides

You can override these environment variables to change behavior.

**Init:**
- `ENVSETUP_INTERACT`: Enables interactive prompts during initialization. The default is `1`.
- `ENVSETUP_KEY_FILE`: Sets the SSH key path that the tool creates during initialization. The default is `$HOME/.ssh/id_rsa`.
- `ENVSETUP_KEY_FILE_COMMENT`: Sets the SSH key comment that the tool creates during initialization. The default is `env-setup:$USER@$(hostname)`.
- `ENVSETUP_INSTALL_DIR`: Sets the path to install `env-setup` during initialization. The default is `$HOME/env-setup`.

**RunTime:**
- `ENVSETUP_INSTALL_DIR`: Sets the path where `env-setup` looks for its `config.yml` files. The default is `$HOME/env-setup`.
- `ANSIBLE_SUDO`: `env-setup` runs Ansible with a sudo prompt (`-K` by default). A value of `-n` disables the prompt.
- `ANSIBLE_CHECK`: `env-setup` runs Ansible with a dry-run check. A value of `-C` enables the check.
- `ANSIBLE_STDOUT_CALLBACK`: `env-setup` runs Ansible with a different status update. The options are `unixy`, `dense`, `debug`, `yaml`, or `selective`. The default is `unixy`.
- `ANSIBLE_PLAYBOOK_INFO`: `env-setup` runs Ansible with a display of playbook steps. A value of `--list-tasks` enables the display.
- `ANSIBLE_SKIPPED_TAGS`: `env-setup` runs Ansible and skips specified tags. The value is a comma-delimited list of tags.
- `ANSIBLE_TAGS`: `env-setup` runs Ansible and runs specific tags. The value is a comma-delimited list of tags.
- `ANSIBLE_VERBOSE`: `env-setup` runs Ansible with verbosity. A value of `-vvv` enables verbosity.

## Testing

`env-setup` has tools to install an environment for testing.

### Docker

The `infra/docker` [directory](infra/docker) contains `Dockerfile` and `Dockerfile.base`. The `Dockerfile.base` builds an accelerated warm base image with common formula dependencies pre-installed to optimize CI and local builds.

You can find pre-built images on [ghcr.io/luciditi/env-setup](https://github.com/Luciditi/env-setup/tree/main/infra/docker#hosted-images). 

To test with a quick command, run `source <(curl -sL jig.io/dev-aliases) && dev-env`. This command installs an alias for `docker run ... ghcr.io/luciditi/env-setup`.

### Terraform

The `terraform` [directory](infra/terraform) is a Terraform module. The module builds an SSH key and EC2 VMs for Linux (Ubuntu 24.04) and macOS (Sonoma). 

After you build the VMs, use the [scripts](infra/terraform/scripts) to test `env-setup` in the new VMs.

### VMs in Tart

Tart VM management and end-to-end testing is built directly into the CLI via `env-setup vm`:

1. Run `env-setup vm create` to clone base Linux and macOS images.
2. Run `env-setup vm start <name>` to launch a VM (e.g., `tahoe-base` or `ubuntu`).
3. Run `env-setup vm ssh <name>` to open a shell or run commands in the VM.
4. Run `env-setup vm env-setup <name> [playbook]` to execute playbooks inside the VM.
5. Run `env-setup vm warm [name]` to pre-install common formulae and Galaxy requirements.
6. Run `env-setup vm test [macos|linux] [target]` to run automated ephemeral end-to-end tests with idempotency assertion (`changed == 0`).
7. Run `env-setup vm stop <name>` to halt the VM.

*(For shell aliases, `eval "$(env-setup -A)"` provides shortcut commands).*

## Custom Playbook

To create a custom playbook, run `./scripts/add-playbook 09-my-playbook`.

This command builds the directory structure in the `ansible` directory. The new playbook is selectable in the `env-setup` tool.

To add your playbook tasks, edit `ansible/*/09-my-playbook/main.yml`. 
To add ansible-galaxy dependencies, edit `ansible/*/09-my-playbook/requirements.yml`.

## Development

Read the development [README](DEV-README.md).

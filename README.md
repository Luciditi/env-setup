# env-setup
<img align="right" width="250" src="https://github.com/Luciditi/env-setup/assets/1087111/7ad0d467-384e-483c-8dcd-b63c19d90c3e">

A workstation provisioner powered by [Ansible](https://www.ansible.com/) / [Homebrew](https://brew.sh/) for either macOS or Linux.

## Quickstart
Get started with `env-setup`:

1. Init: `bash <(curl -sL jig.io/env-setup)`
2. Config: `env-setup -c` 
  - `none`: You want an **empty** config.
  - `mini`: You want a **minimum** config.
  - `default`: You want a **workable default** config.
  - `most`: You want it **all**.
  - `custom`: You want a **new** `config.yml` config started.
3. Run: `env-setup`

## Usage

<img align="right" width="250" src="https://github.com/Luciditi/env-setup/assets/1087111/0e6b5b99-477c-49df-b6f3-42e908dffa8a">

### Init
The initialize command will verify you have `git` & a SSH key to retrieve this 
repo. You'll need to allow a new SSH key in [GitHub](https://github.com/settings/keys) 
if not already set. It will install the tool in your home dir under `env-setup`.
<br /><br /><br /><br /><br /><br /><br />

<img align="right" width="250" src="https://github.com/Luciditi/env-setup/assets/1087111/4abc41e2-79b0-4f11-9504-ce9221852d83">

### Config
The configuration yml file (`config.yml`) contains a **manifest** of Ansible _variables_ 
that define **_what should be installed in your environment_**. You can change the 
values in `config.yml` to fit what your environment setup needs.

`env-setup` has a few starter config templates from these starter scenarios:
  - `none`: You don't need an environment setup, but you want the `env-setup` tool for later use.
  - `mini`: You want a environment setup with only the basic functionality (scripts, Homebrew, & Ansible).
  - `default`: You **workable default** environment setup that will be used semi-often.
  - `most`: You want it **all** in a environment setup that you'll use often.
  - `custom`: You want a **custom** `config.yml` that you'll specify on your own (see an [example config.yml](https://gist.github.com/ShawnConn/2400705e601d6315394f0e4f01bb66b8))

<img align="right" width="250" src="https://github.com/Luciditi/env-setup/assets/1087111/7d30e859-b7c6-4f21-b35d-879ae550a4f7">

### Run
When `env-setup` is first run it will verify you have Ansible. After that, you'll
be prompted to select an Ansible _playbook_ to run. Optionally, you can specify
what playbook to run directly (e.g. `env-setup 01-config` will run the config 
playbook directly, `env-setup all` will run all playbooks in sequential order)
<br /><br /><br /><br /><br /><br /><br />

### Updating
Running `env-setup -u` will update the installed repo alongside the installed 
[dotfiles repo](https://github.com/Luciditi/env-setup-dotfiles). 

### Playbooks
An Ansible _playbook_ is a series of _tasks_ that need to run to get to your wanted setup.
`env-setup` has 8 main playbooks with other optional ones based on your needs.

- `01-config`: Configure your [dotfiles](https://dotfiles.github.io/) for your app & CLI configuration (defaults to [env-setup-dotfiles](https://github.com/Luciditi/env-setup-dotfiles) if not overridden)
- `02-cli`: Install CLI tools via [Homebrew formulas](https://formulae.brew.sh/formula/)
- `03-apps`: Install GUI applications via [Homebrew casks](https://formulae.brew.sh/cask/) & other means (e.g., Linux package manager & App Store via [mas](https://github.com/mas-cli/mas))
- `04-packages`: Install common programming language (Go/Node/PHP/Ruby/Rust/Python) dependencies for development tooling.
- `05-repos`: Clones Git repos used for active development (projects) or reference (vendors).
- `06-os`: Configure the OS settings.
- `07-cloud`: Configure the host for cloud file sync.
- `08-prefs`: Configure any other app settings.

See **custom playbook** section for adding other playbooks as needed.

### Task Info
If you like a _list_ of what _tasks_ in a playbook will do, run `env-setup -i` with 
the playbook name (e.g. `env-setup -i 03-apps`). It will print an ordered task 
list, with a description and tags that describe what the playbook will do.

### Skipping Tasks
If you'd like to _skip_ tasks in a playbook, each task have tags associated 
with them. You can **select tags** with the `-t` option or **skip tags** with the `-s` 
option. You can specify multiple tags by comma-delimiting. For example:

- `env-setup -t node,python 04-packages`: Install only **Node & Python** packages.
- `env-setup -s php 04-packages`: Install all packages, except **PHP** packages.

## Custom Playbook
To get started with a custom playbook: 

- run `./scripts/add-playbook 09-my-playbook`

This will setup the directory structure in the `ansible` dir and make it 
selectable in the `env-setup` tool.

From there, you can edit:
- `ansible/*/09-my-playbook/main.yml` to add your playbook tasks
- `ansible/*/09-my-playbook/requirements.yml` to add any ansible-galaxy dependencies for the playbook.

## Development
See the development [README](DEV-README.md).

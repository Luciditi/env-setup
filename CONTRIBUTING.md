
# Contributing

This project can be forked from this upstream repo and then altered via the steps below to run independently of any code references here.

1. **Project:** [Fork the project](https://github.com/Luciditi/env-setup/fork) into your own space.
1. **Dotfiles:** [Fork the dotfiles](https://github.com/Luciditi/env-setup-dotfiles/fork) into your own space.
1. **Dotfiles:** Update the `*.yml` files in the root of the project so `git@github.com:Luciditi/env-setup-dotfiles` points to your fork.
1. **Bootstrap:** Update [scripts/init](scripts/init) and replace `luciditi` with your own account/org for bootstrap compatibility. 
1. **Bootstrap:** (Optional) Create an [ASCII art file](https://www.asciiart.eu/image-to-ascii) and name it `image.txt`
1. **Bootstrap:** (Optional) Run `./scripts/splash image.txt` to put your logo on the launcher.
1. **Bootstrap:** (Optional) Setup a [router](https://github.com/Luciditi/env-setup/tree/main/infra/router) to handle curl/bash setup (e.g. `bash <(curl -sL example.com/env-setup`)
1. **Docker:** (Optional) Update the `*.config.yml` files so `git@github.com:Luciditi/env-setup-dotfiles` points to your fork(s).
1. **Docker:** (Optional) Update the `infra/docker/Dockerfile` so `git@github.com:Luciditi/env-setup-dotfiles` points to your fork(s).
1. **CI/CD:** (Optional) Update references in `.github/workflows/*.yml` and replace `luciditi` with your own account/org for GHA compatibility. 

If you want to contribute, create a branch minus any of the above changes then create a PR here.

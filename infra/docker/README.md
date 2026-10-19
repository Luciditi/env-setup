# env-setup docker image

A Dockerfile setup that can build a Ubuntu linux image that installs `env-setup`
and all its prerequisites. The image can be configured with a few build arguments:

- `VER`: The default version of the base OS image.
- `PASS`: The default password of `user` (default `password`)
- `ENVSETUP_REPO_SSH`: The default repo of `env-setup` (default `git@github.com:Luciditi/env-setup.git`)
- `ENVSETUP_DOTFILES_REPO_SSH`: The default repo of public dotfiles (default `git@github.com:Luciditi/env-setup-dotfiles.git`)
- `ENVSETUP_DOTFILES_PRV_REPO_SSH`: The default repo of private dotfiles (default `git@github.com:Luciditi/env-setu-dotfiles.git`)
- `ENVSETUP_CONFIG`: The location of the `env-setup` config manifest.
- `ENVSETUP_VERSION`: The version tag of the `env-setup` image.

## Example build steps
Here's an example to build locally:
```
SSH_KEY=$HOME/.ssh/id_rsa
ENVSETUP_CONFIG=default.config.yml
ENVSETUP_VERSION=0.0.0
DOCKERFILE=infra/docker/Dockerfile
#DOCKER_PLATFORMS=linux/amd64,linux/arm64
DOCKER_PLATFORMS=linux/amd64
DOCKER_TAG=$ENVSETUP_VERSION-default

docker buildx build --secret id=ssh,src="$SSH_KEY" --platform $DOCKER_PLATFORMS \
  --build-arg="ENVSETUP_CONFIG=$ENVSETUP_CONFIG" --build-arg="ENVSETUP_VERSION=$ENVSETUP_VERSION" \
  --label "org.opencontainers.image.ref.name=luciditi/env-setup-$DOCKER_TAG" --label "org.opencontainers.image.version=$ENVSETUP_VERSION" \
  -t "env-setup:$DOCKER_TAG" . -f "$DOCKERFILE"
```

## Example run
Here's an example to run locally:
- Run w/ SSH key mounted: `docker run -it --rm --platform linux/amd64 -v "$HOME/.ssh/id_rsa:/home/user/.ssh/id_rsa" ghcr.io/luciditi/env-setup`
- Run w/ SSH key & dotfiles mounted: `docker run -it --rm --platform linux/amd64 -v "$HOME/.ssh/id_rsa:/home/user/.ssh/id_rsa" -v "$HOME/env-setup-dotfiles:/home/user/env-setup-dotfiles" -v "$HOME/env-setup-prv-dotfiles:/home/user/env-setup-prv-dotfiles" ghcr.io/luciditi/env-setup`
- Add aliases in [scripts/aliases](../../scripts/aliases) and start env: `source <(curl -sL jig.io/dev-aliases) && dev-env`

## Hosted images
You can pull images from [the GitHub Container Repo](https://github.com/Luciditi/env-setup/pkgs/container/env-setup).

- `docker pull ghcr.io/luciditi/env-setup`
- `docker pull ghcr.io/luciditi/env-setup:none`
- `docker pull ghcr.io/luciditi/env-setup:mini`
- `docker pull ghcr.io/luciditi/env-setup:most`

# Prerequisites
- An environment that can build a docker image from a `Dockerfile`

# Notes


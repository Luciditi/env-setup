# syntax=docker/dockerfile:1
#
# Ubuntu 24.04 (noble) is REQUIRED, not cosmetic.
#
# Homebrew compares the host glibc/libstdc++ against its CI baseline:
#   LINUX_GLIBC_CI_VERSION     = 2.39   (Homebrew/os.rb)
#   LINUX_LIBSTDCXX_CI_VERSION = 6.0.33
# When the host is below either floor, `needs_libc_formula?` and
# `needs_compiler_formula?` both flip true and Homebrew injects
# source builds of glibc AND gcc into every dependency chain.
#
# Ubuntu 20.04 ships glibc 2.31 / libstdc++ 6.0.28 -- below both. That is why
# every config with a non-empty package list used to build for hours and time
# out at the 6h job cap, while `.none` (empty list) passed in ~5 minutes.
# Ubuntu 24.04 ships glibc 2.39 / libstdc++ 6.0.33 and clears both exactly.
ARG VER=24.04

FROM ubuntu:${VER} AS deps
ENV USER=user
ARG PASS=password
# TZ was "US", which is not a valid zone name.
ENV TZ=Etc/UTC \
    DEBIAN_FRONTEND=noninteractive
# Without these, each serial `brew install` triggers a full homebrew-core
# `git fetch` before doing any work.
ENV HOMEBREW_NO_AUTO_UPDATE=1 \
    HOMEBREW_NO_INSTALL_CLEANUP=1 \
    HOMEBREW_NO_ANALYTICS=1 \
    HOMEBREW_NO_ENV_HINTS=1
RUN apt-get update \
  && apt-get install -y software-properties-common \
  && apt-get install -y \
    build-essential \
    curl \
    git \
    libnotify-bin \ 
    python3 \
    python3-apt \ 
    sudo \
    vim \
  && add-apt-repository --yes --update ppa:ansible/ansible \ 
  && apt-get install -y ansible \
  && rm -rf /var/lib/apt/lists/*
RUN useradd -p "$(openssl passwd -1 ${PASS})" -rm -d "/home/${USER}" -s /bin/bash -g root -G sudo -u 1001 "${USER}"
RUN mkdir -p /home/${USER}/.ssh && \
    ssh-keyscan github.com >> /home/${USER}/.ssh/known_hosts && \ 
    sudo chmod -R 744 /home/${USER}/.ssh && \
    sudo chown -R ${USER}:root /home/${USER}/.ssh
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

FROM deps AS init
ARG ENVSETUP_DOTFILES_PRV_REPO_SSH=git@github.com:Luciditi/env-setup-dotfiles.git
ARG ENVSETUP_DOTFILES_REPO_SSH=git@github.com:Luciditi/env-setup-dotfiles.git
ARG ENVSETUP_REPO_SSH=git@github.com:Luciditi/env-setup.git
ARG ENVSETUP_VERSION=0.0.0
LABEL org.opencontainers.image.authors="env-setup@luciditi.io"
LABEL org.opencontainers.image.description="A development environment created by env-setup."
LABEL org.opencontainers.image.documentation="https://github.com/Luciditi/env-setup"
LABEL org.opencontainers.image.licenses="MIT License"
LABEL org.opencontainers.image.source="https://github.com/Luciditi/env-setup/docker"
LABEL org.opencontainers.image.title="env-setup"
LABEL org.opencontainers.image.url="https://github.com/Luciditi/env-setup"
LABEL org.opencontainers.image.vendor="Luciditi"
USER ${USER}
WORKDIR /home/${USER}
SHELL ["/bin/bash", "-c"]
RUN --mount=type=secret,id=ssh,target="/home/${USER}/.ssh/id_rsa",mode=400,uid=1001,gid=0 \
    git clone ${ENVSETUP_REPO_SSH} /home/${USER}/env-setup
RUN echo "alias env-setup='/home/${USER}/env-setup/scripts/env-setup'" \ 
    >> "/home/${USER}/.bashrc" \
    && echo "source .bash_profile" \
    >> "/home/${USER}/.bashrc" \
    && echo "alias env-setup='/home/${USER}/env-setup/scripts/env-setup'" \ 
    >> "/home/${USER}/.zshrc"

FROM init AS playbooks
ARG ENVSETUP_CONFIG=default.config.yml
COPY ${ENVSETUP_CONFIG} "/home/${USER}/env-setup/config.yml"
RUN /home/${USER}/env-setup/scripts/env-setup

# name: env-setup.01-config ####################################################
RUN --mount=type=secret,id=ssh,target="/home/${USER}/.ssh/id_rsa",mode=400,uid=1001,gid=0 \
    git clone ${ENVSETUP_DOTFILES_REPO_SSH} /home/${USER}/env-setup-dotfiles && \
    git clone ${ENVSETUP_DOTFILES_PRV_REPO_SSH} /home/${USER}/env-setup-prv-dotfiles && \
    /home/${USER}/env-setup/scripts/env-setup 01-config

# name: env-setup.02-cli #######################################################
RUN --mount=type=secret,id=ssh,target="/home/${USER}/.ssh/id_rsa",mode=400,uid=1001,gid=0 \
    /home/${USER}/env-setup/scripts/env-setup 02-cli

# name: env-setup.03-apps ######################################################
#RUN --mount=type=secret,id=ssh,target="/home/${USER}/.ssh/id_rsa",mode=400,uid=1001,gid=0 \
    #/home/${USER}/env-setup/scripts/env-setup 03-apps

# name: env-setup.04-packages ##################################################
RUN --mount=type=secret,id=ssh,target="/home/${USER}/.ssh/id_rsa",mode=400,uid=1001,gid=0 \
    /home/${USER}/env-setup/scripts/env-setup 04-packages

# name: env-setup.05-repos #####################################################
RUN --mount=type=secret,id=ssh,target="/home/${USER}/.ssh/id_rsa",mode=400,uid=1001,gid=0 \
    /home/${USER}/env-setup/scripts/env-setup 05-repos

# name: env-setup.06-os ########################################################
#RUN --mount=type=secret,id=ssh,target="/home/${USER}/.ssh/id_rsa",mode=400,uid=1001,gid=0 \
    #/home/${USER}/env-setup/scripts/env-setup 06-os

# name: env-setup.07-cloud #####################################################
RUN --mount=type=secret,id=ssh,target="/home/${USER}/.ssh/id_rsa",mode=400,uid=1001,gid=0 \
    /home/${USER}/env-setup/scripts/env-setup 07-cloud

# name: env-setup.08-prefs #####################################################
RUN --mount=type=secret,id=ssh,target="/home/${USER}/.ssh/id_rsa",mode=400,uid=1001,gid=0 \
    /home/${USER}/env-setup/scripts/env-setup 08-prefs

FROM playbooks AS boot
RUN ["/home/linuxbrew/.linuxbrew/bin/zsh", "-c", "source ~/.zshrc;"]

CMD ["/home/linuxbrew/.linuxbrew/bin/zsh"]

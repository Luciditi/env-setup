# syntax=docker/dockerfile:1
ARG BASE_IMAGE=ghcr.io/luciditi/env-setup:base-latest

FROM ${BASE_IMAGE} AS init
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

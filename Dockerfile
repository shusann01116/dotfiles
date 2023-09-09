# syntax=docker/dockerfile:1
FROM alpine:3.18.3

ARG USER_NAME=dev
ARG USER_GROUP=dev

RUN apk update && apk add --no-cache \
  sudo \
  git \
  curl \
  wget \
  vim \
  neovim \
  tmux \
  fish \
  bash \
  openssh \
  openssh-client \
  openssh-keygen \
  openssl \
  openssl-dev \
  alpine-sdk \
  go \
  npm \
  fd \
  ripgrep \
  lazygit \
  python3-dev \
  py3-pip

RUN addgroup -S $USER_GROUP && adduser -S $USER_NAME -G $USER_GROUP -s /bin/sh && \
  echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USER_NAME

WORKDIR /home/$USER_NAME

# install astronvim
RUN git clone https://github.com/AstroNvim/AstroNvim ~/.config/nvim
COPY --chown=$USER_NAME:$USER_GROUP ./package/astronvim_config/ ./.config/nvim/lua/user/
RUN nvim --headless +q

ENTRYPOINT ["/usr/bin/nvim"]

FROM alpine:3.18.3

ARG USER_NAME=dev
ARG USER_GROUP=dev

RUN apk add --no-cache \
  sudo \
  git \
  curl \
  wget \
  vim \
  neovim \
  tmux \
  fish \
  openssh \
  openssh-client \
  openssh-keygen \
  openssl \
  openssl-dev

RUN addgroup -S $USER_GROUP && adduser -S $USER_NAME -G $USER_GROUP -s /bin/sh && \
  echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USER_NAME

ENTRYPOINT ["/usr/bin/nvim"]

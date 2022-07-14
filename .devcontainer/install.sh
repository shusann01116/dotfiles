#!/bin/bash

set -uxe

# Install Dagger
OS="$(uname -s)"
ARCH="$(uname -m)"
VERSION="v0.2.23"

[ "$OS" != "Linux" ] && exit 1

OS="linux"

[ "$ARCH" == "aarch64" ] && ARCH="arm64"

DOWNLOAD_URL=https://github.com/dagger/dagger/releases/download/"$VERSION"/dagger_"$VERSION"_"$OS"_"$ARCH".tar.gz

curl -sSLN "$DOWNLOAD_URL" | sudo tar xzf - -C /usr/local/bin

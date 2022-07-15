#!/bin/bash

set -uxe

# Install Dagger
OS="$(uname -s)"
ARCH="$(uname -m)"
VERSION="v0.2.23"

case $OS in
    Linux) OS="linux";;
    Darwin) OS="macOS";;
    *) echo "Not supported OS"; exit 1;;
esac

case $ARCH in
    aarch64) ARCH="arm64";;
    x86_64) ARCH="amd64";;
    *) echo "Not supported platform"; exit 2;;
esac

DOWNLOAD_URL=https://github.com/dagger/dagger/releases/download/"$VERSION"/dagger_"$VERSION"_"$OS"_"$ARCH".tar.gz

curl -sSLN "$DOWNLOAD_URL" | sudo tar xzf - -C /usr/local/bin

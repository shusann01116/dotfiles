#!/bin/bash

if [ -e /etc/os-release ]; then
    OS="linux"
else
    OS=$(sw_vers -productName)
fi

macOS() {
    eval "$(/opt/homebrew/bin/brew shellenv)"
}

linux() {
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
}

[[ $OS == "macOS" ]] && macOS
[[ $OS == "linux" ]] && linux

#!/bin/bash

macOS() {
    eval "$(/opt/homebrew/bin/brew shellenv)"
}

linux() {
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
}

case $(uname -s) in
Linux) linux ;;
Darwin) macOS ;;
*)
    echo "Not supported OS"
    echo 1
    ;;
esac

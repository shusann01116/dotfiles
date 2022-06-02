#!/bin/zsh

set -ue

script_dir="$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd -P)"
dot_dir="$(dirname ${script_dir})"

${dot_dir}/.bin/install.sh
source ${HOME}/.zshrc

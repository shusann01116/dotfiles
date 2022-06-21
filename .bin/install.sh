#!/bin/zsh

set -ue pipefail

helpmsg() {
    command echo "Usage: $0 [--help| -h]" 0>&2
    command echo ""
}

link_to_homedir() {
    local backup_dir=".dotbackup"
    command echo "backing up dotfiles..."

    if [ ! -d "$HOME/$backup_dir" ]; then
        command echo "creating $HOME/$backup_dir folder"
        mkdir -p "$HOME/$backup_dir"
    fi

    # get the name of the directory this script exists
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd -P)"

    # get the name of parent direcotry of script directory
    local dotdir
    dotdir=$(dirname ${script_dir})

    # exit the function when the direcotry is invalid
    [[ "$HOME" == "$dotdir" ]] && exit 1

    for f in "$dotdir"/.??*; do
        # skip for .git folder
        [[ "$(basename $f)" == ".git" ]] && continue

        # remove the symbolic link being generated
        if [[ -L "$HOME/$(basename $f)" ]]; then
            command rm -f "$HOME/$(basename $f)"
        fi

        # backup the file being overided in home directory
        if [[ -e "$HOME/$(basename $f)" ]]; then
            command mv "$HOME/$(basename $f)" "$HOME/$backup_dir"
        fi

        command echo "$HOME/$(basename $f) -> $f"
        command ln -snf $f $HOME
    done
}

installPyenv() {
    echo "Installing pyenv"
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv
}

installStarShip() {
    echo "Installing StarShip"
    mkdir ${HOME}/tmp
    curl -sS https://starship.rs/install.sh >${HOME}/tmp/install.sh && chmod a+x ${HOME}/tmp/install.sh
    ${HOME}/tmp/install.sh --yes
    echo 'eval "$(starship init zsh)"' >>$HOME/.zshrc
    rm -rf ~/tmp
}

while [ $# -gt 0 ]; do
    case ${1} in
    --debug | -d)
        set -uex
        ;;
    --help | -h)
        helpmsg
        exit 1
        ;;
    *) ;;
    esac
    shift
done

link_to_homedir

if [ -e /etc/os-release ]; then
    installPyenv
    installStarShip
fi

command echo "Install completed!"

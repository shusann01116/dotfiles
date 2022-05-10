#!/bin/bash

set -ue

helpmsg() {
    command echo "Usage: $0 [--help| -h]" 0>&2
    command echo ""
}

link_to_homedir() {
    local backup_dir=".dotbackup"
    command echo "backing up dotfiles..."

    if [ ! -d "$HOME/$backup_dir" ]; then
        command echo "creating $HOME/$backup_dir folder"
        mkdir -r "$HOME/$backup_dir"
    fi

    # get the name of the directory this script exists
    local script_dir="$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd -P)"

    # get the name of parent direcotry of script directory
    local dotdir=$(dirname ${script_dir})

    # exit the function when the direcotry is invalid
    [[ "$HOME" == "$dotdir" ]] && exit 1

    for f in $dotdir/.??*; do
        # skip for .git folder
        [[ $(basename $f) == ".git" ]] && continue

        # remove the symbolic link being generated
        if [[ -e "$HOME/$(basename $f)" ]]; then
            command rm -f "$HOME/$(basename $f)"
        fi

        # backup the file being overided in home directory
        if [[ -e "$HOME/$(basename $f)" ]]; then
            command mv "$HOME/$(basename $f)" "$HOME/$backup_dir"
        fi

        command ln -snf "$HOME/$(basename $f)" "$HOME/$(basename $f)"
    done

}

while [ $# -gt 0 ]; do
    case ${1} in
    --debug | -d)
        set -uex
        ;;
    --help | -h)
        helpmsg() exit 1
        ;;
    *) ;;
    esac
    shift
done

link_to_homedir
command echo "Install completed!"

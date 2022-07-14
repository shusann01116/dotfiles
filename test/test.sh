#!/bin/bash
#
# Perform a set of Integration tests inside of the built image.

test_starship() {
    starship --version
}

showhelp() {
    echo "Usage $0"
    echo "-h: Prints help message"
    echo "-d: Debug mode"
    echo "-v: Print message verbose"
    echo ""
    exit 1
}

main() {
    test_starship
}

while getopts 'hdv' flag; do
    case "${flag}" in
    h) showhelp ;;
    d) setopt -eux ;;
    v) setopt -x ;;
    *) ;;
    esac
done

main

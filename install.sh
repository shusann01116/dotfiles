#!/bin/bash

while getopts ':h' OPT; do
  case $OPT in
    h)
      show_help
      exit 0
      ;;
    *)
      ;;
  esac
done
shift $(($OPTIND - 1))

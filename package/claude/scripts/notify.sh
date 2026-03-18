#!/bin/bash
# Claude Code hook notification script
# Usage: notify.sh <message> [sound]
message="${1:-Notification}"
sound="${2:-default}"

session=$(tmux display-message -p '#S' 2>/dev/null)
dir=${PWD##*/}

subtitle="${session:+[$session] }$dir"

osascript -e "display notification \"$message\" with title \"Claude Code\" subtitle \"$subtitle\" sound name \"$sound\""

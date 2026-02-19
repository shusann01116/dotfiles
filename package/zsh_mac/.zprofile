eval "$(/opt/homebrew/bin/brew shellenv)"
export COLORTERM=truecolor # for tmux to support true color

# XDG Base Directory
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Claude Code: use XDG-based config directory
export CLAUDE_CONFIG_DIR="$XDG_CONFIG_HOME/claude"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
export COLORTERM=truecolor # for tmux to support true color

# XDG Base Directory
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Claude Code: use XDG-based config directory
export CLAUDE_CONFIG_DIR="$XDG_CONFIG_HOME/claude"

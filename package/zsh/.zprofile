if [[ -d /opt/homebrew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
elif [[ -d /home/linuxbrew/.linuxbrew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
elif [[ -d $HOME/.linuxbrew ]]; then
  eval "$("${HOME}"/.linuxbrew/bin/brew shellenv zsh)"
fi
export COLORTERM=truecolor # for tmux to support true color

# Claude Code: use XDG-based config directory
export CLAUDE_CONFIG_DIR="$XDG_CONFIG_HOME/claude"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source "$HOME"/.orbstack/shell/init.zsh 2>/dev/null || :

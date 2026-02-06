# Oh My Zsh configuration file
# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
zstyle ':omz:update' mode auto # update automatically without asking
zstyle ':omz:update' frequency 13
ENABLE_CORRECTION="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
plugins=(git alias-finder)

zstyle ':omz:plugins:alias-finder' autoload yes

source $ZSH/oh-my-zsh.sh

# User configuration
export LANG=en_US.UTF-8
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

export PATH="/opt/homebrew/bin:$PATH"

# ghq
export GHQ_ROOT="${HOME}/src"
function ghq-fzf() {
  local src=$(ghq list | fzf --preview "bat --color=always --style=header,grid --line-range :80 $(ghq root)/{}/README.*")
  if [ -n "$src" ]; then
    BUFFER="cd $(ghq root)/$src"
    zle accept-line
  fi
  zle -R -c
}
zle -N ghq-fzf
bindkey '^g' ghq-fzf

alias v=nvim
alias k=kubectl
alias lg=lazygit
alias d=docker
alias ld=lazydocker
alias b=bat
alias ..='cd ..'

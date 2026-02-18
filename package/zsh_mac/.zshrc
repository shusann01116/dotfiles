export PATH="$HOME/.local/bin:$PATH"

# Oh My Zsh configuration file
# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
zstyle ':omz:update' mode auto # update automatically without asking
zstyle ':omz:update' frequency 13
DISABLE_UNTRACKED_FILES_DIRTY="true"
plugins=(alias-finder)

zstyle ':omz:plugins:alias-finder' autoload yes

source $ZSH/oh-my-zsh.sh

# User configuration
export LANG=en_US.UTF-8
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# env
export PATH="/opt/homebrew/bin:$PATH"
export GITHUB_PERSONAL_ACCESS_TOKEN="$(security find-generic-password -a $USER -s github-pat -w 2>/dev/null)"


# aliases
alias g=git
alias p=pnpm
alias v=nvim
alias k=kubectl
alias lg=lazygit
alias d=docker
alias ld=lazydocker
alias b=bat
alias ..='cd ..'

# completions
if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
if command -v zsh >/dev/null 2>&1; then eval "$(mise activate zsh)"; fi
if command -v zoxide >/dev/null 2>&1; then eval "$(zoxide init zsh)"; fi

# dotfilesのこだわりを晒す
# https://www.m3tech.blog/entry/dotfiles-bonsai
case "$OSTYPE" in
    darwin*)
        (( ${+commands[gdate]} )) && alias date='gdate'
        (( ${+commands[gls]} )) && alias ls='gls'
        (( ${+commands[gmkdir]} )) && alias mkdir='gmkdir'
        (( ${+commands[gcp]} )) && alias cp='gcp'
        (( ${+commands[gmv]} )) && alias mv='gmv'
        (( ${+commands[grm]} )) && alias rm='grm'
        (( ${+commands[gdu]} )) && alias du='gdu'
        (( ${+commands[ghead]} )) && alias head='ghead'
        (( ${+commands[gtail]} )) && alias tail='gtail'
        (( ${+commands[gsed]} )) && alias sed='gsed'
        (( ${+commands[ggrep]} )) && alias grep='ggrep'
        (( ${+commands[gfind]} )) && alias find='gfind'
        (( ${+commands[gdirname]} )) && alias dirname='gdirname'
        (( ${+commands[gxargs]} )) && alias xargs='gxargs'
    ;;
esac

zshaddhistory() {
    local line="${1%%$'\n'}"
    [[ ! "$line" =~ "^(cd|jj?|lazygit|la|ll|ls|rm|rmdir)($| )" ]]
}

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

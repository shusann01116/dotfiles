# color
autoload -Uz colors && colors

# zip unzip
export PATH="/opt/homebrew/opt/zip/bin:$PATH"
export PATH="/opt/homebrew/opt/unzip/bin:$PATH"

# dotnet
export DOTNET_ROOT="opt/homebrew/opt/dotnet/libexec:$PATH"

# starship
eval "$(starship init zsh)"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# h5py
export HDF5_DIR="/opt/homebrew/opt/hdf5"

# aliases
alias zsource='source ~/.zshrc'

alias ll="ls -al"
alias la="ls -a"

alias mv="mv -f"
alias cp="cp -f"
alias rm="rm -f"

alias ls='exa --time-style=long-iso -g'
alias ll='ls --git --time-style=long-iso -gl'
alias la='ls --git --time-style=long-iso -agl'
alias l1='exa -1'

alias gch='git checkout'
alias gchb='git checkout -b'
alias gcom='git commit'
alias gp='git push'
alias gpu='git pull'

# completion
if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
    autoload -Uz compinit && compinit
fi
zstyle ':completion:*' menu select
zstyle ':completion:*' rehash true

# autosuggestions
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# no history duplications
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/shusann/.pyenv/versions/miniforge3-4.10.3-10/bin/conda' 'shell.zsh' 'hook' 2>/dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/shusann/.pyenv/versions/miniforge3-4.10.3-10/etc/profile.d/conda.sh" ]; then
        . "/Users/shusann/.pyenv/versions/miniforge3-4.10.3-10/etc/profile.d/conda.sh"
    else
        export PATH="/Users/shusann/.pyenv/versions/miniforge3-4.10.3-10/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# use gihub for vsCode container extension
# ref: https://code.visualstudio.com/docs/remote/containers#_using-ssh-keys
ssh-add ~/.ssh/id_ed25519

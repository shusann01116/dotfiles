# Starship
eval "$(starship init zsh)"

# aliases
if [ -f ${HOME}/.zshaliases ]; then
  source ${HOME}/.zshaliases
fi

# envs
if [ -f ${HOME}/.zshenv ]; then
  source ${HOME}/.zshenv
fi

#################################################
# completions
#################################################

# brew completions
FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

fpath=($fpath ~/.zsh/completion)

# Enable bashcompinit
autoload -Uz compinit
compinit
autoload -U +X bashcompinit && bashcompinit

complete -C 'aws_completer' aws
source <(kubectl completion zsh)
source <(docker completion zsh)
complete -o nospace -C $(brew --prefix)/bin/terraform terraform

#################################################
# zsh features
#################################################

zstyle ':completion:*' menu select
zstyle ':completion:*' rehash true

# no history duplications
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

# syntax highlighting
source /home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

#################################################
# miscellaneous
#################################################

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Export path to the autoloader for the Bash Function Library.
# See https://github.com/jmooring/bash-function-library.
if [ -f "/home/shusann/.lib/bfl/autoload.sh" ]; then
  export BASH_FUNCTION_LIBRARY="/home/shusann/.lib/bfl/autoload.sh"
fi

# auto suggestions
source /home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/shusann/.local/google-cloud-sdk/path.zsh.inc' ]; then . '/home/shusann/.local/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/shusann/.local/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/shusann/.local/google-cloud-sdk/completion.zsh.inc'; fi

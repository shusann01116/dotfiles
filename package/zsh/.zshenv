export EDITOR=nvim
export TERM=xterm-256color

# local
export PATH="$HOME/.local/bin:$PATH"

# go
export PATH=${HOME}/go/bin:$PATH

# node
export PATH="/opt/homebrew/opt/node@16/bin:$PATH"

# h5py
export HDF5_DIR="/opt/homebrew/opt/hdf5"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# dotnet
export DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec:$PATH"

# zip unzip
export PATH="/opt/homebrew/opt/zip/bin:$PATH"
export PATH="/opt/homebrew/opt/unzip/bin:$PATH"

export GPG_TTY=$(tty)

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


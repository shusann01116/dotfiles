export EDITOR=nvim

# local
export PATH="$HOME/.local/bin:$PATH"

# go
export PATH=${HOME}/go/bin:$PATH

# node
export PATH="/opt/homebrew/opt/node@16/bin:$PATH"

# h5py
export HDF5_DIR="/opt/homebrew/opt/hdf5"

# dotnet
export DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec:$PATH"

# zip unzip
export PATH="/opt/homebrew/opt/zip/bin:$PATH"
export PATH="/opt/homebrew/opt/unzip/bin:$PATH"

# mise shim
export PATH="$HOME/.local/share/mise/shims:$PATH"

# yarn global path
[[ -x "$(command -v yarn)" ]] && export PATH="$(yarn global bin):$PATH"

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools

# ghq
export GHQ_ROOT="${HOME}/src"

export GPG_TTY=$(tty)
. "$HOME/.cargo/env"

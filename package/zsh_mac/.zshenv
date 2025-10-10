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

# java
export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

# ghq
export GHQ_ROOT="${HOME}/src"

export GPG_TTY=$(tty)
. "$HOME/.cargo/env"

#!/bin/bash

set -euo pipefail

info() {
  echo ""
  echo "Info: $1"
}

debug() {
  if [[ -n "${DEBUG-}" ]]; then
    echo ""
    echo "Debug: $1"
  fi
}

error() {
  echo ""
  echo "Error: $1"
}

unset HAVE_SUDO_ACCESS

have_sudo_access() {
  if [[ ! -x "/usr/bin/sudo" ]]; then
    error "sudo is not installed"
    exit 1
  fi

  local -a SUDO=("/usr/bin/sudo")
  if [[ -n "${SUDO_ASKPASS-}" ]]; then
    SUDO+=("-A")
  elif [[ -n "${NONINTERACTIVE-}" ]]; then
    SUDO+=("-n")
  fi

  if [[ -z "${HAVE_SUDO_ACCESS-}" ]]; then
    if [[ -n "${NONINTERACTIVE-}" ]]; then
      "${SUDO[@]}" -l mkdir &>/dev/null
    else
      "${SUDO[@]}" -v && "${SUDO[@]}" -l mkdir &>/dev/null
    fi
    HAVE_SUDO_ACCESS="$?"
  fi

  return "${HAVE_SUDO_ACCESS}"
}

execute() {
  if ! "$@"; then
    error "Failed to execute: $*"
    exit 1
  fi
}

execute_sudo() {
  local -a args=("$@")
  if have_sudo_access; then
    if [[ -n "${SUDO_ASKPASS-}" ]]; then
      args=("-A" "${args[@]}")
    fi
    info "Executing: sudo ${args[*]}"
    /usr/bin/sudo "${args[@]}"
  else
    info "Executing: ${args[*]}"
    "${args[@]}"
  fi
}

ensure_installed_dependencies() {
  dependencies=$1
  for dependency in $dependencies; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
      error "Missing dependency: $dependency"
      exit 1
    fi
  done
}

backup_file() {
  file=$1

  local time
  time=$(date +%Y%m%d%H%M%S)

  if [[ -e "$file" ]]; then
    info "Backing up $file to $file.$time.bak"
    mv "$file" "$file.$time.bak"
  fi
}

link_file() {
  src=$1
  dest=$2

  info "Linking $src to $dest"
  ln -sf "$src" "$dest"
}

tmux() {
  if ! command -v tmux >/dev/null 2>&1; then
    info "Installing tmux..."
    brew install tmux
  fi

  backup_file "$HOME/.tmux.conf"
  backup_file "$HOME/.tmux.conf.local"
  link_file "$PACKAGE_ROOT/tmux/.tmux.conf" "$HOME/.tmux.conf"
  link_file "$PACKAGE_ROOT/tmux/.tmux.conf.local" "$HOME/.tmux.conf.local"
}

homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    info "Installing homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
}

install_brew_tap() {
  if ! command -v brew >/dev/null 2>&1; then
    error "Homebrew is not installed"
    return 1
  fi

  local -a taps="$1"
  info "Installing brew taps..."
  for tap in $taps; do
    execute brew tap "$tap"
  done

  return $?
}

install_brew_app() {
  if ! command -v brew >/dev/null 2>&1; then
    error "Homebrew is not installed"
    return 1
  fi

  local apps="$1"
  info "Installing brew apps..."
  execute echo "${apps}" | xargs brew install

  return $?
}

neovim() {
  if ! command -v nvim >/dev/null 2>&1; then
    info "Installing neovim..."
    brew install neovim
  fi

  backup_file "$HOME/.config/nvim"
  backup_file "$HOME/.local/share/nvim"
  backup_file "$HOME/.local/state/nvim"
  backup_file "$HOME/.cache/nvim"

  ln -s "$(pwd)/package/astronvim_config" "$HOME/.config/nvim"
}

zsh() {
  if ! command -v zsh >/dev/null 2>&1; then
    info "Installing zsh..."
    brew install zsh
  fi

  local -a zsh_dotfiles=(
    .zshrc
    .zprofile
  )

  for dotfile in "${zsh_dotfiles[@]}"; do
    backup_file "$HOME/$dotfile"
    [[ -f "$PACKAGE_ROOT/zsh/$dotfile" ]] && link_file "$PACKAGE_ROOT/zsh/$dotfile" "$HOME/$dotfile"
  done

  return $?
}

claude() {
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/claude"
  mkdir -p "$config_dir"

  local -a claude_files=(
    CLAUDE.md
    settings.json
  )

  for file in "${claude_files[@]}"; do
    backup_file "$config_dir/$file"
    [[ -f "$PACKAGE_ROOT/claude/$file" ]] && link_file "$PACKAGE_ROOT/claude/$file" "$config_dir/$file"
  done

  # Agents（個別ファイル単位でリンク、ローカル専用agentとの共存を許容）
  if [[ -d "$PACKAGE_ROOT/claude/agents" ]]; then
    mkdir -p "$config_dir/agents"
    chmod 700 "$config_dir/agents"
    for agent_file in "$PACKAGE_ROOT/claude/agents"/*.md; do
      [[ -f "$agent_file" ]] || continue
      local agent_name
      agent_name=$(basename "$agent_file")
      backup_file "$config_dir/agents/$agent_name"
      link_file "$agent_file" "$config_dir/agents/$agent_name"
    done
  fi

  # Scripts（hookから呼び出すスクリプト群をリンク）
  if [[ -d "$PACKAGE_ROOT/claude/scripts" ]]; then
    mkdir -p "$config_dir/scripts"
    for script_file in "$PACKAGE_ROOT/claude/scripts"/*; do
      [[ -f "$script_file" ]] || continue
      local script_name
      script_name=$(basename "$script_file")
      backup_file "$config_dir/scripts/$script_name"
      link_file "$script_file" "$config_dir/scripts/$script_name"
    done
  fi

  # Hooks（PreToolUse 等のフックスクリプトをリンク）
  if [[ -d "$PACKAGE_ROOT/claude/hooks" ]]; then
    mkdir -p "$config_dir/hooks"
    for hook_file in "$PACKAGE_ROOT/claude/hooks"/*; do
      [[ -f "$hook_file" ]] || continue
      local hook_name
      hook_name=$(basename "$hook_file")
      backup_file "$config_dir/hooks/$hook_name"
      link_file "$hook_file" "$config_dir/hooks/$hook_name"
    done
  fi

  # Skills（カスタムスキルのみ個別にリンク、外部symlinksを壊さない）
  if [[ -d "$PACKAGE_ROOT/claude/skills" ]]; then
    mkdir -p "$config_dir/skills"
    for skill_item in "$PACKAGE_ROOT/claude/skills"/*; do
      [[ -e "$skill_item" ]] || continue
      local skill_name
      skill_name=$(basename "$skill_item")
      backup_file "$config_dir/skills/$skill_name"
      link_file "$skill_item" "$config_dir/skills/$skill_name"
    done
  fi
}

linux() {
  info "Entering linux setup..."
  execute_sudo apt-get update && execute_sudo apt-get install -y build-essential curl file git || exit 1
  homebrew
  install_brew_tap "$(tr '\n' ' ' <"$PACKAGE_ROOT/brew/brewtap")"
  install_brew_app "$(tr '\n' ' ' <"$PACKAGE_ROOT/brew/brewlist")"
  tmux
  neovim
  zsh
  claude

  return $?
}

macos() {
  info "Entering macos setup..."
  homebrew
  install_brew_tap "$(tr '\n' ' ' <"$PACKAGE_ROOT/brew/brewtap")"
  install_brew_app "$(tr '\n' ' ' <"$PACKAGE_ROOT/brew/brewlist")"
  tmux
  neovim
  zsh
  claude

  return $?
}

main() {
  if [[ -z "${PACKAGE_ROOT-}" ]]; then
    debug "Using PACKAGE_ROOT to $(pwd)/package"
    PACKAGE_ROOT="$(pwd)/package"
  fi

  os=$(uname -s)
  case $os in
  Darwin)
    macos
    ;;
  Linux)
    linux
    ;;
  *)
    error "Unsupported OS: $os"
    exit 1
    ;;
  esac
}

main
info "Done!"

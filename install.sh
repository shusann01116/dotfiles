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

	git clone --depth 1 https://github.com/AstroNvim/AstroNvim ~/.config/nvim
	git clone https://github.com/shusann01116/astronvim_config ~/.config/nvim/lua/user
}

zsh() {
	local os=$1
	if ! command -v zsh >/dev/null 2>&1; then
		info "Installing zsh..."
		brew install zsh
	fi

	local -a zsh_dotfiles=(
		.zshrc
		.zshenv
		.zprofile
		.zsh
	)

	for dotfile in "${zsh_dotfiles[@]}"; do
		backup_file "$HOME/$dotfile"
		[[ -f "$PACKAGE_ROOT/zsh_$os/$dotfile" ]] && link_file "$PACKAGE_ROOT/zsh_$os/$dotfile" "$HOME/$dotfile"
	done

	return $?
}

linux() {
	info "Entering linux setup..."
	execute_sudo apt-get update && execute_sudo apt-get install -y build-essential curl file git || exit 1
	homebrew
	install_brew_tap "$(tr '\n' ' ' <"$PACKAGE_ROOT/brew/brewtap")"
	install_brew_app "$(tr '\n' ' ' <"$PACKAGE_ROOT/brew/brewlist")"
	tmux
	neovim
	zsh wsl

	return $?
}

macos() {
	info "Entering macos setup..."
	homebrew
	install_brew_tap "$(tr '\n' ' ' <"$PACKAGE_ROOT/brew/brewtap")"
	install_brew_app "$(tr '\n' ' ' <"$PACKAGE_ROOT/brew/brewlist")"
	tmux
	neovim
	zsh mac

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

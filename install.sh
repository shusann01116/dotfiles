#!/bin/bash

set -euo pipefail

info() {
  echo ""
  echo "Info: $1"
}

error() {
  echo ""
  echo "Error: $1"
}

FLAKE_HOST="shusann-mac"
PACKAGE_ROOT="${PACKAGE_ROOT:-$(pwd)/package}"

install_nix() {
  if command -v nix >/dev/null 2>&1; then
    info "Nix already installed: $(nix --version)"
    return
  fi
  info "Installing Determinate Nix..."
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
}

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi
  info "Installing Homebrew (packages themselves are managed by nix-darwin)..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

trust_brew_taps() {
  # brew refuses to load formulae from untrusted third-party taps; trust the
  # taps declared in modules/darwin/homebrew.nix before the switch needs them.
  local tap
  for tap in koekeishiya/formulae datadog-labs/pack raine/workmux; do
    brew trust "$tap" 2>/dev/null || true
  done
}

darwin_switch() {
  if command -v darwin-rebuild >/dev/null 2>&1; then
    sudo darwin-rebuild switch --flake ".#${FLAKE_HOST}"
  else
    info "Bootstrapping nix-darwin (first run on this machine)..."
    sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ".#${FLAKE_HOST}"
  fi
}

register_herdr_plugins() {
  # herdr plugin registration talks to a running server — imperative and
  # stateful, so it stays here rather than in home-manager activation.
  local plugin_id plugin_dir
  for plugin_id in shusann.worktree-bootstrap shusann.hunk-diff; do
    plugin_dir="$PACKAGE_ROOT/herdr/plugins/${plugin_id#shusann.}"
    if [[ -n "$(type -P herdr)" ]] && [[ -f "$plugin_dir/herdr-plugin.toml" ]]; then
      if command herdr plugin list 2>/dev/null | grep -q "$plugin_id"; then
        info "herdr plugin ${plugin_id#shusann.} already linked"
      else
        info "Linking herdr plugin ${plugin_id#shusann.}"
        command herdr plugin link "$plugin_dir" || info "herdr plugin link failed (link manually once the herdr server is running)"
      fi
    fi
  done
}

main() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    error "This bootstrap targets macOS. For WSL/Linux: install Determinate Nix, then 'nix run home-manager -- switch --flake .#shusann'"
    exit 1
  fi
  install_nix
  install_homebrew
  trust_brew_taps
  darwin_switch
  register_herdr_plugins
  info "Done!"
}

main "$@"

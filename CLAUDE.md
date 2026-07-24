# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Overview

This is a cross-platform dotfiles repository optimized for modern development
workflows. It supports both macOS and Linux environments with automated
installation and package management through Homebrew.

## Installation and Setup

```bash
# Bootstrap a new Mac (idempotent)
./install.sh

# The script only bootstraps; everything else is Nix-managed:
# 1. Determinate Nix (if not present)
# 2. Homebrew (if not present; packages are managed by nix-darwin, not this script)
# 3. brew trust for the third-party taps declared in modules/darwin/homebrew.nix
# 4. sudo darwin-rebuild switch --flake .#shusann-mac
# 5. herdr plugin registration (imperative; talks to the running server)

# Day-to-day: edit modules/ (or package/ configs), then
sudo darwin-rebuild switch --flake .#shusann-mac
```

## Development Tools and Commands

### Package Management

Packages are declared in Nix, not installed imperatively:

- **Cross-platform CLI tools** → `home.packages` in `modules/home/default.nix` (nixpkgs)
- **Casks and mac-only/tap formulae** → `modules/darwin/homebrew.nix` (nix-darwin's homebrew module; `cleanup = "none"` during migration, `autoUpdate = false`)
- **Language runtimes** → mise (`package/mise/config.toml`), never Nix or brew

```bash
# Add a package: edit the relevant file above, then
sudo darwin-rebuild switch --flake .#shusann-mac

# Upgrade nixpkgs-managed tools (deliberate, not automatic)
nix flake update && sudo darwin-rebuild switch --flake .#shusann-mac
```

### Development Environment

- **Primary Editor**: Neovim with AstroNvim configuration
- **Shell**: Zsh with Oh My Zsh
- **Terminal Emulator**: Wezterm
- **Terminal Multiplexer**: tmux with custom configuration
- **Version Manager**: mise for managing development tool versions

### Key Development Tools Included

- **Languages**: Go, Rust, Node.js, Python 3.11, .NET
- **DevOps**: Docker, Kubernetes CLI, Terraform, AWS CLI, Dagger
- **Git Tools**: lazygit, GitHub CLI (gh)
- **Modern CLI**: fd, ripgrep, lsd, starship prompt, bat, zoxide
- **Language Servers**: terraform-ls, yaml-language-server, omnisharp

## Architecture

### Nix Layout (hosts/ and modules/)

- `flake.nix` - inputs (nixpkgs, nix-darwin, home-manager, hunk) and outputs
  - `darwinConfigurations."shusann-mac"` - the Mac (nix-darwin + home-manager, one `darwin-rebuild switch` applies both)
  - `homeConfigurations."shusann"` - no-sudo fallback; a WSL variant is added when a host exists
- `hosts/shusann-mac/` - host identity (platform, primary user)
- `modules/darwin/` - macOS system config; `homebrew.nix` declares taps/brews/casks; `nix.enable = false` because **Determinate Nix owns the daemon/GC** (custom nix settings go in `/etc/nix/nix.custom.conf`)
- `modules/home/` - shared home config: `default.nix` (packages, programs.*), `dotfiles.nix` (the `dotfiles.dir` option, derived from the ghq root `~/src`), `symlinks.nix` + `claude.nix` (dotfile links), `darwin.nix` (mac-only)

All dotfile symlinks use `mkOutOfStoreSymlink` into `package/`, so configs stay live-editable in the repo — no rebuild needed to test a config edit. **Flake purity caveat:** new files under `package/claude/` (agents, skills) must be `git add`ed before they get linked on the next switch.

### Package-Based Organization

Each tool/application has its own directory under `package/` (the content source that `modules/home/` symlinks into place):

- `package/zsh/` - Zsh shell configuration (Oh My Zsh)
- `package/tmux/` - Terminal multiplexer configuration
- `package/herdr/` - herdr (terminal workspace manager) config and plugins
  - `plugins/worktree-bootstrap/` - `worktree.created` 時に対象リポジトリの
    `.herdr/setup`（ローカル限定スクリプト）を可視タブで自動実行する汎用プラグイン
- `package/wezterm/` - Wezterm terminal emulator configuration
- `package/astronvim_config/` - Custom Neovim configuration (vendored directly, formerly a git submodule)
- `package/claude/` - Claude Code global config (settings.json, CLAUDE.md, agents, skills)
- `package/yabai/` + `package/skhd/` - macOS window management (tiling WM)

### Claude Code Configuration

Claude Code のコンフィグディレクトリは `CLAUDE_CONFIG_DIR` 環境変数で `$XDG_CONFIG_HOME/claude` (`~/.config/claude/`) に設定されている（`package/zsh/.zprofile` で export）。

`modules/home/claude.nix` が `builtins.readDir` で `package/claude/` を列挙し、個別ファイル単位で symlink を張る:

- `settings.json`, `CLAUDE.md` → `~/.config/claude/` 直下にリンク
- `agents/`, `skills/`（将来 `scripts/`, `hooks/`）→ 個別エントリ単位でリンク。`~/.config/claude/` は実ディレクトリのまま維持され、ローカル限定の agent/skill やセッション状態と共存する
- 新規ファイルは `git add` してから `darwin-rebuild switch` で反映される（flake は git-tracked ファイルしか見えない）

**注意**: `package/claude/settings.json` が実体であり、`~/.config/claude/settings.json` はシンボリックリンク。編集は `package/claude/settings.json` に対して行うこと。

### Installation Strategy

`install.sh` is a thin macOS bootstrap (Determinate Nix → Homebrew → tap trust → `darwin-rebuild switch` → herdr plugins). Symlinks and packages are entirely managed by nix-darwin/home-manager; the script has no symlink or package-list logic.

## Development Workflow

### Pre-commit Hooks

This repository uses pre-commit hooks for code quality:

- **end-of-file-fixer** - Ensures files end with a newline
- **trailing-whitespace** - Removes trailing whitespace
- **markdownlint** - Lints Markdown files
- **prettier** - Formats supported files
- **hadolint** - Lints Dockerfiles

Run manually: `pre-commit run --all-files`

### EditorConfig

All files follow `.editorconfig` settings:

- Charset: UTF-8
- Line endings: LF
- Indent: 2 spaces
- Trim trailing whitespace
- Insert final newline

### Dependabot

Automated dependency updates via `.github/dependabot.yml`:

- **GitHub Actions**: weekly updates

## Common Development Patterns

### Adding New Tools

1. Cross-platform CLI → add to `home.packages` in `modules/home/default.nix`; cask/mac-only → add to `modules/darwin/homebrew.nix`
2. Add configuration files to a `package/<tool>/` directory
3. Link the config: add an `xdg.configFile` entry in `modules/home/symlinks.nix` (via the `pkg` helper)
4. `sudo darwin-rebuild switch --flake .#shusann-mac`

### Zsh Aliases

Key aliases defined in `package/zsh/.zshrc`:

- `v` → nvim
- `lg` → lazygit
- `g` → git
- `k` → kubectl
- `d` → docker
- `p` → pnpm
- `ld` → lazydocker
- `b` → bat

### Path Management

Zsh adds these to PATH via `.zshrc` and `.zprofile`:

- `$HOME/.local/bin`
- `/opt/homebrew/bin` (macOS Homebrew)

Additional paths are managed by mise for language-specific toolchains.

## Special Features

### macOS Window Management

- Yabai provides BSP tiling window management
- SKHD handles keyboard shortcuts for window manipulation
- Alt+click for mouse-based window operations

### Secrets Management

- Pulumi secrets stored in `$HOME/.config/secrets/pulumi-secret`
- GPG TTY properly configured for commit signing
- GitHub PAT retrieved from macOS Keychain via `security` command

## Configuration Files to Modify

When adding new tools or making changes:

- **modules/home/default.nix** - Add nixpkgs CLI tools (home.packages)
- **modules/darwin/homebrew.nix** - Add Homebrew casks / mac-only formulae
- **modules/home/symlinks.nix** - Add dotfile symlinks for new `package/<tool>/` dirs
- **package/zsh/.zshrc** - Add aliases, environment variables
- **package/mise/config.toml** - Manage language versions
- **package/wezterm/wezterm.lua** - Terminal emulator configuration
- **package/claude/settings.json** - Claude Code permissions and settings
- **install.sh** - Bootstrap-only changes (Nix/Homebrew install, tap trust, herdr plugins)

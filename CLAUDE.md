# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Overview

This is a cross-platform dotfiles repository optimized for modern development
workflows. It supports both macOS and Linux environments with automated
installation and package management through Homebrew.

## Installation and Setup

```bash
# Full environment setup
./install.sh

# The script auto-detects platform (macOS/Linux) and installs:
# - Homebrew (if not present)
# - All packages from package/brew/brewlist
# - Zsh with Oh My Zsh
# - Neovim with AstroNvim
# - tmux configuration
# - Claude Code configuration (XDG_CONFIG_HOME aware)
```

## Development Tools and Commands

### Package Management

```bash
# View all managed packages
cat package/brew/brewlist

# Install new package (add to brewlist for persistence)
brew install <package>

# Update all packages
brew update && brew upgrade
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

### Package-Based Organization

Each tool/application has its own directory under `package/`:

- `package/brew/` - Homebrew package lists (brewlist, brewtap)
- `package/zsh/` - Zsh shell configuration (Oh My Zsh)
- `package/tmux/` - Terminal multiplexer configuration
- `package/wezterm/` - Wezterm terminal emulator configuration
- `package/astronvim_config/` - Custom Neovim configuration (git submodule)
- `package/claude/` - Claude Code global config (settings.json, CLAUDE.md, agents, skills)
- `package/yabai/` + `package/skhd/` - macOS window management (tiling WM)

### Claude Code Configuration

Claude Code のコンフィグディレクトリは `CLAUDE_CONFIG_DIR` 環境変数で `$XDG_CONFIG_HOME/claude` (`~/.config/claude/`) に設定されている（`package/zsh/.zprofile` で export）。

`install.sh` の `claude()` 関数により以下のシンボリックリンクが作成される:

- `settings.json`, `CLAUDE.md` → `~/.config/claude/` 直下にリンク
- `agents/`, `skills/` → 個別ファイル単位で `~/.config/claude/agents/`, `~/.config/claude/skills/` にリンク

**注意**: `package/claude/settings.json` が実体であり、`~/.config/claude/settings.json` はシンボリックリンク。編集は `package/claude/settings.json` に対して行うこと。

### Installation Strategy

The install.sh script:

1. Detects platform (Darwin/Linux)
2. Installs Homebrew if missing
3. Backs up existing configurations with timestamps
4. Creates symbolic links from package/ directories to expected locations
5. Runs platform-specific setup (linux() or macos() functions)
6. Installs Claude Code config to `$XDG_CONFIG_HOME/claude`

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
- **Git submodules (root)**: monthly updates
- **AstroNvim submodule**: daily updates

## Common Development Patterns

### Adding New Tools

1. Add package to `package/brew/brewlist`
2. Run `brew install <package>`
3. Add configuration files to appropriate `package/<tool>/` directory
4. Update install.sh if symlinks needed

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

- **package/brew/brewlist** - Add new Homebrew packages
- **package/zsh/.zshrc** - Add aliases, environment variables
- **package/mise/config.toml** - Manage language versions
- **package/wezterm/wezterm.lua** - Terminal emulator configuration
- **package/claude/settings.json** - Claude Code permissions and settings
- **install.sh** - Add new symlink operations or installation steps

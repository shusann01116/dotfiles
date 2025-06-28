# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Overview

This is a cross-platform dotfiles repository optimized for modern development
workflows. It supports both macOS and Linux/WSL environments with automated
installation and package management through Homebrew.

## Installation and Setup

```bash
# Full environment setup
./install.sh

# The script auto-detects platform (macOS/Linux) and installs:
# - Homebrew (if not present)
# - All packages from package/brew/brewlist
# - Configured shells (Fish/Zsh)
# - Neovim with AstroNvim
# - tmux configuration
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
- **Shell**: Fish (primary) with vi-mode, Zsh (macOS/WSL variants)
- **Terminal Multiplexer**: tmux with custom configuration
- **Version Manager**: mise for managing development tool versions

### Key Development Tools Included

- **Languages**: Go, Rust, Node.js, Python 3.11, .NET
- **DevOps**: Docker, Kubernetes CLI, Terraform, AWS CLI, Dagger
- **Git Tools**: lazygit, GitHub CLI (gh)
- **Modern CLI**: fd, ripgrep, lsd, starship prompt
- **Language Servers**: terraform-ls, yaml-language-server

## Architecture

### Package-Based Organization

Each tool/application has its own directory under `package/`:

- `package/fish/` - Fish shell configuration with aliases and completions
- `package/brew/` - Homebrew package lists (brewlist, brewtap)
- `package/mise/` - Development tool version configuration
- `package/tmux/` - Terminal multiplexer configuration
- `package/astronvim_config/` - Custom Neovim configuration (git submodule)

### Platform-Specific Configurations

- `package/zsh_mac/` - macOS-specific Zsh configuration
- `package/zsh_wsl/` - WSL/Linux-specific Zsh configuration
- `package/yabai/` + `package/skhd/` - macOS window management (tiling WM)

### Installation Strategy

The install.sh script:

1. Detects platform (Darwin/Linux)
2. Installs Homebrew if missing
3. Backs up existing configurations with timestamps
4. Creates symbolic links from package/ directories to expected locations
5. Runs platform-specific setup (linux() or macos() functions)

## Common Development Patterns

### Adding New Tools

1. Add package to `package/brew/brewlist`
2. Run `brew install <package>`
3. Add configuration files to appropriate `package/<tool>/` directory
4. Update install.sh if symlinks needed

### Fish Shell Aliases

Key aliases defined in `package/fish/config.fish`:

- `v` → nvim
- `lg` → lazygit
- `tf` → terraform
- `k` → kubectl
- `g` → git
- `d` → docker

### Path Management

Fish automatically adds these to PATH:

- `$HOME/.local/bin`
- `$HOME/go/bin` (Go binaries)
- `$HOME/.cargo/bin` (Rust binaries)
- `$HOME/.dotnet/tools` (.NET tools)

## Special Features

### Containerized Development

- `Dockerfile` creates Alpine Linux environment with full toolchain
- Pre-configured with AstroNvim setup
- Useful for consistent development environments

### macOS Window Management

- Yabai provides BSP tiling window management
- SKHD handles keyboard shortcuts for window manipulation
- Alt+click for mouse-based window operations

### Secrets Management

- Pulumi secrets stored in `$HOME/.config/secrets/pulumi-secret`
- GPG TTY properly configured for commit signing

## Configuration Files to Modify

When adding new tools or making changes:

- **package/brew/brewlist** - Add new Homebrew packages
- **package/fish/config.fish** - Add aliases, environment variables
- **package/mise/config.toml** - Manage language versions
- **install.sh** - Add new symlink operations or installation steps

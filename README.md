# dotfiles

My dotfiles for macOS (nix-darwin + home-manager), structured for a future WSL host

- nix-darwin + home-manager (packages, dotfile symlinks, declarative Homebrew)
- tmux
- neovim with [AstroNeovim](https://github.com/AstroNvim/AstroNvim) and [custom config](package/astronvim_config)

## Install

```shell
git clone https://github.com/shusann01116/dotfiles.git ~/src/github.com/shusann01116/dotfiles  # ghq layout is assumed
cd ~/src/github.com/shusann01116/dotfiles
./install.sh
```

Day-to-day, after editing `modules/` or `package/`:

```shell
sudo darwin-rebuild switch --flake .#shusann-mac
```

{ ... }:

{
  home.homeDirectory = "/home/shusann";

  # Non-NixOS distro (Ubuntu, WSL, ...): wire up XDG_DATA_DIRS, locale, etc.
  # for Nix-installed programs.
  targets.genericLinux.enable = true;
}

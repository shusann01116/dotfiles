{ lib, ... }:

{
  home.homeDirectory = "/home/shusann";

  # Non-NixOS distro (Ubuntu, WSL, ...): wire up XDG_DATA_DIRS, locale, etc.
  # for Nix-installed programs.
  targets.genericLinux.enable = true;

  # hunk is built with nixpkgs' bun, which requires AVX2; the ThinkPad X230
  # (Ivy Bridge) lacks it and bun dies with SIGILL during the build.
  programs.hunk.enable = lib.mkForce false;
  programs.git.settings.core.pager = lib.mkForce "less";
}

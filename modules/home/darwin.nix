{ config, pkgs, ... }:

let
  pkg = subpath: config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.dir}/package/${subpath}";
in
{
  home.homeDirectory = "/Users/shusann";

  # macOS tiling WM (yabai + skhd) — no Linux equivalent here.
  home.packages = with pkgs; [
    yabai
    skhd
  ];

  xdg.configFile = {
    "yabai".source = pkg "yabai";
    "skhd".source = pkg "skhd";
  };
}

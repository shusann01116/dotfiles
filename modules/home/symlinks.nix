{ config, ... }:

let
  pkg = subpath: config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.dir}/package/${subpath}";
in
{
  xdg.configFile = {
    "nvim".source = pkg "astronvim_config";
    "zsh".source = pkg "zsh";
    "wezterm".source = pkg "wezterm";
    "yabai".source = pkg "yabai";
    "skhd".source = pkg "skhd";
  };

  # ZDOTDIR bootstrap — the one file that must live directly in $HOME.
  home.file.".zshenv".source = pkg "zsh/.zshenv";
}

{ config, lib, ... }:

{
  options.dotfiles = {
    dir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/src/github.com/shusann01116/dotfiles";
      description = ''
        Absolute path to this repo's checkout. Derived from the ghq root
        convention (ghq root = ~/src); hosts with a different layout override it.
      '';
    };
  };
}

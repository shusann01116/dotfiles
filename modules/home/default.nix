{ inputs, pkgs, ... }:

{
  imports = [
    inputs.hunk.homeManagerModules.default
  ];

  home.username = "shusann";
  home.stateVersion = "26.05";

  home.packages = [
    pkgs.ripgrep
    pkgs.fzf
    pkgs.htop
    pkgs.bat
    pkgs.ghq
    pkgs.gh
    pkgs.yazi
  ];

  xdg.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    settings = {
      pull = {
        ff = "only";
      };
      core = {
        pager = "hunk pager";
      };
      user = {
        name = "shusann01116";
        email = "26602565+shusann01116@users.noreply.github.com";
      };
    };
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.lazygit = {
    enable = true;
  };

  programs.hunk = {
    enable = true;
    enableGitIntegration = true;
    settings = {
      theme = "graphite";
      mode = "split";
      line_numbers = true;
    };
  };
}

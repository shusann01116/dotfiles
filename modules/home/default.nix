{ inputs, pkgs, ... }:

{
  imports = [
    inputs.hunk.homeManagerModules.default
    ./dotfiles.nix
    ./symlinks.nix
    ./claude.nix
  ];

  home.username = "shusann";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # originals
    ripgrep
    fzf
    htop
    bat
    ghq
    gh
    yazi
    # cross-platform CLI moved off Homebrew (curated from `brew leaves`)
    act
    cloc
    cmake
    coreutils
    duckdb
    ffmpeg
    findutils
    fx
    ghz
    gnupg
    gnused
    golangci-lint
    grpcurl
    kubernetes-helm # brew: helm
    istioctl
    jq
    kind
    kubectx
    kustomize
    lazydocker
    lftp
    lsd
    luaPackages.luacheck
    minikube
    mise
    neovim
    nkf
    nushell
    openapi-generator-cli
    protobuf
    pwgen
    stylua
    tmux
    tree
    uv
    wabt
    watchman
    xplr
    zip
    zoxide
    _7zz # brew: sevenzip
    libwebp # brew: webp
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

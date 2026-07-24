{ ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false; # upgrades are deliberate, not switch side-effects
      cleanup = "none"; # migration safety; flip to "zap" post-migration
    };

    taps = [
      "koekeishiya/formulae"
      "datadog-labs/pack"
      "raine/workmux"
    ];

    brews = [
      # mac-bound / tap-scoped / unfree-in-nixpkgs formulae
      "agent-browser"
      "colima"
      "crit"
      "docker"
      "docker-buildx"
      "docker-compose"
      "docker-credential-helper"
      "gemini-cli"
      "googleworkspace-cli"
      "gperftools"
      "herdr"
      "icu4c@76"
      "libimobiledevice"
      "libpq"
      "librsvg"
      "llvm"
      "mactop"
      "mingw-w64"
      "pkgconf"
      "postgresql@15"
      "postgresql@18"
      "datadog-labs/pack/pup"
      "samply"
      "koekeishiya/formulae/skhd"
      "terminal-notifier"
      # terraform/tfenv intentionally undeclared: terraform is mise-managed,
      # and brew's terraform link conflicts with tfenv's shim
      "worktrunk"
      "raine/workmux/workmux"
      "xcodegen"
      "koekeishiya/formulae/yabai"
      "zsh-autosuggestions"
      "zsh-syntax-highlighting"
    ];

    casks = [
      "1password"
      "1password-cli"
      "alt-tab"
      "aqua-voice"
      "bettershot"
      "capcut"
      "claude"
      "cmux"
      "copilot-cli"
      "cursor"
      "dbeaver-community"
      "figma"
      "firefox"
      "font-fira-code"
      "font-hack-nerd-font"
      "font-hackgen"
      "font-jetbrains-mono"
      "font-noto-sans-jp"
      "font-symbols-only-nerd-font"
      "gcloud-cli" # renamed from google-cloud-sdk
      "google-japanese-ime"
      "hyperkey"
      "karabiner-elements"
      "keycastr"
      "microsoft-edge"
      "nani"
      "notion"
      "notion-calendar"
      "notion-mail"
      "obsidian"
      "postman"
      "raycast"
      "slack"
      "spotify"
      "unnaturalscrollwheels"
      "wezterm"
      "zed"
      "zoom"
      "zulu@17"
    ];
  };
}

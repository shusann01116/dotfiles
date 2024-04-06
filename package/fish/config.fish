if test $(uname) = "Darwin"
  eval "$(/opt/homebrew/bin/brew shellenv)"
end

if status is-interactive
  # Commands to run in interactive sessions can go here
  fish_add_path /sbin
  fish_add_path /usr/local/bin
  fish_add_path -m $HOME/.local/bin
  fish_add_path -m $HOME/.pulumi/bin
  fish_add_path -m $HOME/go/bin
  fish_add_path -m $HOME/.cargo/bin
  fish_add_path -m $HOME/.dotnet/tools

  # Setup fish
  set BROWSER /usr/bin/wslview
  starship init fish | source

  fish_vi_key_bindings

  # AWS CLI completion
  function __fish_complete_aws
      env COMP_LINE=(commandline -pc) aws_completer | tr -d ' '
  end
  complete -c aws -f -a "(__fish_complete_aws)"

  # Pulumi secrets
  if type -q pulumi
    set SECRET_PATH $HOME/.config/secrets/pulumi-secret
    if test -f $SECRET_PATH
      set -x PULUMI_CONFIG_PASSPHRASE (cat $SECRET_PATH)
    end
  end

  # alias
  alias v=nvim
  alias tf=terraform
  alias tg=terragrunt
  alias lg=lazygit
  alias a=aws
  alias d=docker
  alias g=git
  alias lg=lazygit
  alias tg=terragrunt
  alias k=kubectl
  alias ls=lsd
end

export GPG_TTY=$(tty)

# pnpm
set -gx PNPM_HOME "/Users/shusann/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

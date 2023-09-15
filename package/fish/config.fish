if test $(uname) = "Darwin"
  eval "$(/opt/homebrew/bin/brew shellenv)"
end

if status is-interactive
  # Commands to run in interactive sessions can go here
  fish_add_path /sbin
  fish_add_path /usr/local/bin
  fish_add_path -m $HOME/.local/bin
  fish_add_path -m $HOME/.pulumi/bin

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
  alias t=terraform
  alias l=lazygit
  alias g=git
  alias k=kubectl
end

export GPG_TTY=$(tty)

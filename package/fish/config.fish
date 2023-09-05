if status is-interactive
    # Commands to run in interactive sessions can go here
    set PATH $PATH:/sbin
    set PATH $PATH:/usr/local/bin
    set PATH $PATH:$HOME/.local/bin
    set BROWSER /usr/bin/wslview
    starship init fish | source

    fish_vi_key_bindings

    # AWS CLI completion
    function __fish_complete_aws
        env COMP_LINE=(commandline -pc) aws_completer | tr -d ' '
    end

    complete -c aws -f -a "(__fish_complete_aws)"

    # alias
    alias v=nvim
    alias t=terraform
    alias l=lazygit
    alias g=git
    alias k=kubectl
end

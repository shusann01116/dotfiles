# load base
if [ -f ~/.zshrc.base ]; then
  source ~/.zshrc.base
fi

# load alias
if [ -f ~/.zshaliases ]; then
    source ~/.zshaliases
fi

# load completions
if [ -f ~/.zshcompletions ]; then
    source ~/.zshcompletions
fi

# import env
if [ -f ~/.zshenv ]; then
  source ~/.zshenv
fi

# completions
if [ -f ~/.zshcomp ]; then
  source ~/.zshcomp
fi

# use gihub for vsCode container extension
# ref: https://code.visualstudio.com/docs/remote/containers#_using-ssh-keys
if [ "$(ssh-add -l | wc -m)" -eq 29 ]; then
	[ ! -e ~/.ssh ] && echo "SSH-key has not been generated"
	[ -e ~/.ssh/id_ed25519 ] && ssh-add ~/.ssh/id_ed25519 || true
fi

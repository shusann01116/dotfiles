# import env
if [ -f ~/.zshenv ]; then
  source ~/.zshenv
fi

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

# completions
if [ -f ~/.zshcomp ]; then
  source ~/.zshcomp
fi

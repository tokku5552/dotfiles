# zshrc
# flutter
export PATH=$PATH:$HOME/fvm/default/bin:/usr/local/Cellar/cocoapods/1.10.0/bin
export PATH=$PATH:$HOME/.nodebrew/current/bin
export PATH=$PATH:$HOME/.pub-cache/bin
export PATH=$PATH:~/development/flutter/bin

# nodebrew
export PATH=$HOME/.nodebrew/current/bin:$PATH

# ruby
[[ -d ~/.rbenv ]] &&
  export PATH=${HOME}/.rbenv/bin:${PATH} &&
  eval "$(rbenv init -)"

# php
export PATH="$HOME/.phpenv/bin:$PATH"
eval "$(phpenv init -)"
export PATH="/usr/local/opt/bison/bin:$PATH"

# other
export PATH="/usr/local/opt/openjdk@11/bin:$PATH"

# alias
alias ll='ls -l'
alias la='ls -la'

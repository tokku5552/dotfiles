# zshrc

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# flutter
export PATH=$PATH:$HOME/fvm/default/bin:/usr/local/Cellar/cocoapods/1.10.0/bin
export PATH=$PATH:$HOME/.pub-cache/bin
export PATH=$PATH:~/development/flutter/bin

# ruby
[[ -d ~/.rbenv ]] &&
  export PATH=${HOME}/.rbenv/bin:${PATH} &&
  eval "$(rbenv init -)"

# php
[[ -d ~/.phpenv ]] &&
  export PATH="$HOME/.phpenv/bin:$PATH" &&
  eval "$(phpenv init -)" &&
  export PATH="/usr/local/opt/bison/bin:$PATH"

# for golang
eval "$(/opt/homebrew/bin/brew shellenv)" 
export PATH="$PATH:/opt/homebrew/bin" 
export GOPATH="$HOME/go" 
export PATH="$GOPATH/bin:$PATH"

# for nodeenv
export PATH="$HOME/.nodenv/bin:$PATH"
eval "$(nodenv init -)"

export AWS_REGION="ap-northeast-1"

# other
export PATH="/usr/local/opt/openjdk@11/bin:$PATH"

# alias
alias ll='ls -l'
alias la='ls -la'

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
eval "$(brew shellenv)"
export PATH="$PATH:/opt/homebrew/bin"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# for nodeenv
# export PATH="$HOME/.nodenv/bin:$PATH"
# eval "$(nodenv init -)"

export AWS_REGION="ap-northeast-1"

# other
export PATH="/usr/local/opt/openjdk@11/bin:$PATH"

# alias
alias ll='ls -l'
alias la='ls -la'

# asdf setting
. $(brew --prefix asdf)/libexec/asdf.sh

# for mysql-client
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"

# for java 17
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
export JAVA_HOME=$(/usr/libexec/java_home -v 17)

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f $HOME/.dart-cli-completion/zsh-config.zsh ]] && . $HOME/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]

export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export PATH="/opt/homebrew/opt/mysql-client@8.4/bin:$PATH"

eval "$(direnv hook zsh)"

# pyenv
[[ -d ~/.pyenv ]] &&
  export PYENV_ROOT="$HOME/.pyenv" &&
  command -v pyenv >/dev/null && {
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
}

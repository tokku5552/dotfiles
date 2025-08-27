#
# Defines environment variables.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ ( "$SHLVL" -eq 1 && ! -o LOGIN ) && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi

# Load local zshenv configuration (not shared on GitHub)
if [[ -s "$HOME/dotfiles/zsh/.zshenv.local" ]]; then
  source "$HOME/dotfiles/zsh/.zshenv.local"
fi

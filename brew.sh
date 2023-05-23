#!/bin/sh

# brew install
brew doctor
brew update --verbose
brew upgrade --verbose
brew bundle --file .Brewfile --verbose
brew cleanup --verbose

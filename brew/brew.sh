#!/usr/bin/env bash

# Check for Homebrew,
# Install if we don't have it
if test ! $(which brew); then
  print_subtitle "Installing homebrew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade --greedy

# Applications
brew install 1password
brew install airflow
brew install arc
brew install figma
brew install google-drive
brew install notion
brew install raycast
brew install spotify
brew install vlc

# Remove outdated versions from the cellar.
brew cleanup

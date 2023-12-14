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
brew_install 1password
brew_install airflow
brew_install arc
brew_install figma
brew_install google-drive
brew_install notion
brew_install raycast
brew_install spotify
brew_install vlc

# Remove outdated versions from the cellar.
brew cleanup
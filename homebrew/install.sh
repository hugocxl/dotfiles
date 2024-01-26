#!/usr/bin/env bash

# Check for Homebrew,
# Install if we don't have it
if test ! $(which brew); then
  print_subtitle "Installing homebrew..."

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

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
brew_install meetingbar
brew_install notion
brew_install raycast
brew_install spotify
brew_install visual-studio-code
brew_install vlc
brew_install cocoapods

# Remove outdated versions from the cellar.
brew cleanup

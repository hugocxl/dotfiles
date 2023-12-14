#!/usr/bin/env bash

# Install useful binaries
print_subtitle "Installing useful binaries"

brew install git
brew install zsh
brew install nvm
brew install cocoapods
brew install pnpm
brew install rustup

# Applications
print_subtitle "Installing applications for development"

brew_install docker
brew_install figma
brew_install gitkraken
brew_install minisim
brew_install postman
brew_install table-plus
brew_install visual-studio-code

# Git
print_subtitle "Configuring git"

source devtools/git/install.sh

# Zsh
print_subtitle "Configuring zsh"

source devtools/zsh/install.sh

# Remove outdated versions from the cellar.
brew cleanup

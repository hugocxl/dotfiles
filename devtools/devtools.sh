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

brew install docker
brew install figma
brew install gitkraken
brew install minisim
brew install postman
brew install table-plus
brew install visual-studio-code

# Git
print_subtitle "Configuring git"

source devtools/git/git.sh

# Zsh
print_subtitle "Configuring zsh"

source devtools/zsh/zsh.sh

# Remove outdated versions from the cellar.
brew cleanup

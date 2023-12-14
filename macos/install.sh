#!/usr/bin/env bash

# Step 1: Update the OS and Install Xcode Tools
print_subtitle "Updating OSX.  If this requires a restart, run the script again"
# Install all available updates
sudo softwareupdate -i -a

print_subtitle "Installing Xcode Command Line Tools."
# Install Xcode command line tools
sudo xcode-select --install

#!/usr/bin/env bash

columns=$(tput cols)
divider1=$(printf '#%.0s' $(seq 1 $columns))
divider2=$(printf '_%.0s' $(seq 1 $columns))

print_title() {
    local title_text="$1"
    local terminal_width=$(tput cols)
    local title_length=$((terminal_width - ${#title_text} - 3))
    echo ""
    echo "\033[1;104m ${title_text} $(printf ' %.0s' $(seq 1 "$title_length"))\033[0m"
}

print_subtitle() {
    local title_text="$1"
    echo ""
    echo "\033[1;34m${title_text}\033[0m"
}

brew_install() {
    # Check if a Cask program ID is provided as an argument
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <cask_program_id>"
        return 1
    fi

    cask_program_id=$1

    print_subtitle "Installing ${cask_program_id}"
    # Check if the application is already installed in the Applications folder
    if [ -d "/Applications/$cask_program_id.app" ]; then
        echo "\033[1;34m # ${cask_program_id}\033[0m: already installed"
    else
        print_subtitle "Installing ${cask_program_id}"

        brew install $cask_program_id
    fi
}

# Ask for the administrator password upfront
sudo -v

function install() {
    # Run the osx.sh script
    print_title "Updating OSX and installing Xcode command line tools"
    source ./macos/install.sh

    # # Run the macos.sh script
    print_title "Setting sensible OSX defaults"
    source ./macos/defaults.sh

    # # Run the brew.sh script
    print_title "Installing Homebrew along with some common formulae and apps"
    echo "This might awhile to complete, as some formulae need to be installed from source."
    echo ""
    source ./homebrew/install.sh

    # Copy config files
    print_title "Installing devtools apps and configuration"
    source ./devtools/install.sh

    print_title "Complete!"
    echo "Restart your computer to ensure all updates take effect"
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
    install
else
    read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install
    fi
fi
unset install

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

# Ask for the administrator password upfront
sudo -v

function install() {
    # Run the osx.sh script
    print_title "Updating OSX and installing Xcode command line tools"
    source ./macos/osx.sh

    # # Run the macos.sh script
    print_title "Setting sensible OSX defaults"
    source ./macos/macos.sh

    # # Run the brew.sh script
    print_title "Installing Homebrew along with some common formulae and apps"
    echo "This might awhile to complete, as some formulae need to be installed from source."
    echo ""
    source ./brew/brew.sh

    # Copy config files
    print_title "Installing devtools apps and configuration"
    source ./devtools/devtools.sh

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

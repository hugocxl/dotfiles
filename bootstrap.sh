#!/bin/bash
# One-liner for a brand-new Mac:
#
#   curl -fsSL https://raw.githubusercontent.com/hugocxl/dotfiles/master/bootstrap.sh | bash
#
# Gets git (via the Command Line Tools), clones this repo to ~/repos/dotfiles,
# then hands over to install.sh. Extra arguments are passed through.

set -euo pipefail

REPO="${DOTFILES_REPO:-https://github.com/hugocxl/dotfiles.git}"
DEST="${DOTFILES_DIR:-$HOME/repos/dotfiles}"

if ! xcode-select -p &>/dev/null; then
  echo "==> Installing Xcode Command Line Tools (needed for git)"
  flag=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  touch "$flag"
  label=$(softwareupdate -l 2>/dev/null | sed -n 's/^.*Label: \(Command Line Tools.*\)$/\1/p' | sort -V | tail -1)
  rm -f "$flag"
  if [[ -n $label ]]; then
    sudo softwareupdate -i "$label"
  else
    xcode-select --install
    read -r -p "Press Enter once the installer has finished. " </dev/tty
  fi
fi

if [[ -d $DEST/.git ]]; then
  echo "==> Updating $DEST"
  git -C "$DEST" pull --ff-only
else
  echo "==> Cloning dotfiles into $DEST"
  mkdir -p "$(dirname "$DEST")"
  git clone "$REPO" "$DEST"
fi

# Reattach stdin to the terminal: under `curl | bash` it's the script itself
exec "$DEST/install.sh" "$@" </dev/tty

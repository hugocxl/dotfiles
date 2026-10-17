#!/usr/bin/env bash
# Set up a new Mac, or re-apply everything to an existing one. Every step is
# idempotent, so it's safe to run again after pulling changes.
#
#   ./install.sh               run every step
#   ./install.sh git vscode    run only some steps
#   ./install.sh --yes         accept every default, no questions
#   ./install.sh --list        list the steps

set -euo pipefail
cd "$(dirname "$0")"
source lib/utils.sh

STEPS="xcode homebrew packages dotfiles git ssh languages vscode macos"

describe() {
  case $1 in
    xcode)     echo "Xcode Command Line Tools" ;;
    homebrew)  echo "Homebrew" ;;
    packages)  echo "CLI tools and apps from the Brewfile" ;;
    dotfiles)  echo "Link zsh and mise config into ~" ;;
    git)       echo "Git config, identity and GitHub login" ;;
    ssh)       echo "SSH key in the macOS keychain" ;;
    languages) echo "Node, pnpm, bun (mise) and Rust" ;;
    vscode)    echo "VS Code settings, keybindings and extensions" ;;
    macos)     echo "macOS defaults, security and software updates" ;;
  esac
}

# --- Steps -------------------------------------------------------------------

step_xcode() {
  if xcode-select -p &>/dev/null; then
    ok "Already installed"
    return
  fi
  # Install headlessly through softwareupdate instead of the GUI prompt
  local flag=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress label
  touch "$flag"
  label=$(softwareupdate -l 2>/dev/null | sed -n 's/^.*Label: \(Command Line Tools.*\)$/\1/p' | sort -V | tail -1)
  rm -f "$flag"
  if [[ -n $label ]]; then
    sudo softwareupdate -i "$label"
  else
    xcode-select --install
    read -r -p "  Press Enter once the installer has finished. "
  fi
  xcode-select -p &>/dev/null || die "Command Line Tools are still missing"
  ok "Installed"
}

step_homebrew() {
  if ! [[ -x $(brew_prefix)/bin/brew ]]; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$("$(brew_prefix)/bin/brew" shellenv)"
  brew analytics off
  brew update --quiet
  ok "Homebrew $(brew --version | head -1 | cut -d' ' -f2)"
}

step_packages() {
  # --adopt takes over apps that were installed by hand instead of failing
  if HOMEBREW_CASK_OPTS="--adopt" brew bundle --file=Brewfile; then
    ok "Everything in the Brewfile is installed"
  else
    warn "Some packages failed. Fix them, then run: ./install.sh packages"
  fi
}

step_dotfiles() {
  link zsh/.zshrc "$HOME/.zshrc"
  link zsh/.zprofile "$HOME/.zprofile"
  link mise/config.toml "$HOME/.config/mise/config.toml"

  [[ $SHELL == */zsh ]] || chsh -s /bin/zsh
  if [[ -d $HOME/.oh-my-zsh ]]; then
    info "Oh My Zsh is no longer used; remove it with: rm -rf ~/.oh-my-zsh"
  fi
}

step_git() {
  link git/config "$HOME/.config/git/config"
  link git/ignore "$HOME/.config/git/ignore"

  # A ~/.gitconfig would override the XDG config, so carry over the identity
  # from it and move it out of the way.
  local old_name old_email
  if [[ -f $HOME/.gitconfig ]]; then
    old_name=$(git config --file "$HOME/.gitconfig" user.name || true)
    old_email=$(git config --file "$HOME/.gitconfig" user.email || true)
    backup "$HOME/.gitconfig"
  fi

  local local_config="$HOME/.config/git/config.local"
  if [[ -z $(git config --file "$local_config" user.email 2>/dev/null || true) ]]; then
    local name email
    name=$(prompt "Git name" "${old_name:-$(id -F)}")
    email=$(prompt "Git email" "${old_email:-}")
    git config --file "$local_config" user.name "$name"
    git config --file "$local_config" user.email "$email"
  fi
  ok "Committing as $(git config user.name) <$(git config user.email)>"

  if has gh && ! gh auth status &>/dev/null && ask "Log in to GitHub now?"; then
    gh auth login --git-protocol ssh --web
  fi
}

step_ssh() {
  local key="$HOME/.ssh/id_ed25519"
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"

  if [[ ! -f $key ]] && ask "Create an SSH key?"; then
    ssh-keygen -t ed25519 -C "$(git config user.email || whoami)" -f "$key"
  fi
  [[ -f $key ]] || return 0

  # Load keys from the macOS keychain so the passphrase is asked only once
  if ! grep -q "UseKeychain" "$HOME/.ssh/config" 2>/dev/null; then
    printf '\nHost *\n  AddKeysToAgent yes\n  UseKeychain yes\n  IdentityFile %s\n' "$key" >>"$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
  fi
  ssh-add --apple-use-keychain "$key" 2>/dev/null || true
  ok "SSH key: $key.pub"

  if has gh && gh auth status &>/dev/null && ! gh ssh-key list 2>/dev/null | grep -q "$(cut -d' ' -f2 "$key.pub")"; then
    if ask "Add this key to your GitHub account?"; then
      gh ssh-key add "$key.pub" --title "$(scutil --get ComputerName)"
    fi
  fi
}

step_languages() {
  if has mise; then
    mise install --yes
    ok "$(mise ls --current | wc -l | tr -d " ") tools from mise/config.toml"
  fi
  if has rustup || [[ -x $(brew_prefix)/opt/rustup/bin/rustup ]]; then
    PATH="$(brew_prefix)/opt/rustup/bin:$PATH" rustup default stable >/dev/null
    ok "Rust stable"
  fi
}

step_vscode() {
  local user_dir="$HOME/Library/Application Support/Code/User"
  link vscode/settings.json "$user_dir/settings.json"
  link vscode/keybindings.json "$user_dir/keybindings.json"

  if ! has code; then
    warn "The 'code' command is missing; skipping extensions"
    return
  fi
  local installed ext
  installed=$(code --list-extensions | tr '[:upper:]' '[:lower:]')
  while read -r ext; do
    [[ -z $ext || $ext == \#* ]] && continue
    if ! grep -qx "$(echo "$ext" | tr '[:upper:]' '[:lower:]')" <<<"$installed"; then
      code --install-extension "$ext" >/dev/null && ok "$ext" || warn "Couldn't install $ext"
    fi
  done <vscode/extensions.txt
  ok "Extensions up to date"
}

step_macos() {
  if ask "Apply the macOS defaults in macos/defaults.sh?"; then
    bash macos/defaults.sh
  fi
  bash macos/security.sh

  title "Software updates"
  if ask "Install pending macOS updates now? (may restart)" n; then
    sudo softwareupdate --install --all --agree-to-license
  fi
}

# --- Main --------------------------------------------------------------------

usage() {
  sed -n '2,9s/^# \{0,1\}//p' "$0"
  exit "${1:-0}"
}

selected=""
while (($#)); do
  case $1 in
    -y | --yes) export DOTFILES_YES=1 ;;
    -h | --help) usage ;;
    -l | --list)
      for step in $STEPS; do printf '  %-10s %s\n' "$step" "$(describe "$step")"; done
      exit 0
      ;;
    -*) usage 1 ;;
    *)
      [[ " $STEPS " == *" $1 "* ]] || die "Unknown step '$1'. See --list."
      selected="$selected $1"
      ;;
  esac
  shift
done

[[ $(uname) == Darwin ]] || die "These dotfiles are for macOS"
[[ $EUID -ne 0 ]] || die "Run as your user, not root"

printf '%sdotfiles%s · macOS %s · %s\n' "$BOLD" "$RESET" "$(sw_vers -productVersion)" "$(uname -m)"
sudo_keepalive

# Homebrew must be on PATH for every step after it
[[ -x $(brew_prefix)/bin/brew ]] && eval "$("$(brew_prefix)/bin/brew" shellenv)"

for step in ${selected:-$STEPS}; do
  title "$(describe "$step")"
  "step_$step"
done

title "Done"
info "Open a new terminal (or run: exec zsh -l) to load the new shell config."
info "Log out and back in for keyboard and trackpad changes to take effect."

#!/usr/bin/env bash
# Set up a new Mac, or re-apply everything to an existing one. Every step is
# idempotent, so it's safe to run again after pulling changes.
#
#   ./install.sh               run every step
#   ./install.sh git ssh       run only some steps
#   ./install.sh --yes         accept every default, no questions
#   ./install.sh --list        list the steps

set -euo pipefail
cd "$(dirname "$0")"
source lib/utils.sh

# Developer ID team that signs Yab (21st Labs Inc.)
YAB_TEAM_ID=25UG4QYN9F

STEPS="xcode homebrew packages dotfiles git ssh languages muxy macos"

describe() {
  case $1 in
    xcode)     echo "Xcode Command Line Tools" ;;
    homebrew)  echo "Homebrew" ;;
    packages)  echo "CLI tools and apps from the Brewfile, plus Yab" ;;
    dotfiles)  echo "Link zsh, mise and yazi config into ~" ;;
    git)       echo "Git config, identity and GitHub login" ;;
    ssh)       echo "SSH key in the macOS keychain" ;;
    languages) echo "Node, pnpm and bun (mise)" ;;
    muxy)      echo "Muxy settings" ;;
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
  install_yab || warn "Couldn't install Yab. Download it from https://yetanotherbrowser.com"
}

# Yab isn't on Homebrew. Install it from its update feed, checking the download's
# checksum and signature; once installed it updates itself.
install_yab() {
  if [[ -d /Applications/yab.app ]]; then
    ok "Yab"
    return
  fi
  local feed url sha tmp app
  feed=$(curl -fsSL https://yetanotherbrowser.com/appcast.json) || return 1
  url=$(plutil -extract url raw -o - - <<<"$feed") || return 1
  sha=$(plutil -extract sha256 raw -o - - <<<"$feed") || return 1
  tmp=$(mktemp -d)
  curl -fsSL "$url" -o "$tmp/yab.zip" || return 1
  if [[ $(shasum -a 256 "$tmp/yab.zip" | cut -d' ' -f1) != "$sha" ]]; then
    warn "Yab download doesn't match its checksum"
    return 1
  fi
  ditto -xk "$tmp/yab.zip" "$tmp" || return 1
  app="$tmp/yab.app"
  codesign --verify --deep --strict "$app" || return 1
  [[ $(codesign -dv "$app" 2>&1) == *"TeamIdentifier=$YAB_TEAM_ID"* ]] || return 1
  ditto "$app" /Applications/yab.app || return 1
  rm -rf "$tmp"
  ok "Yab installed"
}

step_dotfiles() {
  link zsh/.zshrc "$HOME/.zshrc"
  link zsh/.zprofile "$HOME/.zprofile"
  link mise/config.toml "$HOME/.config/mise/config.toml"
  link yazi/theme.toml "$HOME/.config/yazi/theme.toml"

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
    # The ssh step creates and uploads the key itself, so skip gh's own key prompt
    # but ask for the scopes it needs.
    gh auth login --git-protocol ssh --web --skip-ssh-key --scopes admin:public_key,admin:ssh_signing_key ||
      warn "GitHub login didn't finish. Run it later with: ./install.sh git"
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

  # Sign commits and tags with the same key
  local local_config="$HOME/.config/git/config.local"
  if [[ -z $(git config --file "$local_config" user.signingkey 2>/dev/null || true) ]] &&
    ask "Sign your commits with this SSH key?"; then
    git config --file "$local_config" gpg.format ssh
    git config --file "$local_config" user.signingkey "$key.pub"
    git config --file "$local_config" commit.gpgsign true
    git config --file "$local_config" tag.gpgsign true
    ok "Commits will be signed"
  fi

  has gh && gh auth status &>/dev/null || return 0
  # One line per key on GitHub, ending in its type: authentication or signing
  local pub keys title
  pub=$(cut -d' ' -f2 "$key.pub")
  keys=$(gh ssh-key list 2>/dev/null | grep -F "$pub" || true)
  title=$(scutil --get ComputerName)
  if [[ $keys != *authentication* ]] && ask "Add this key to your GitHub account?"; then
    gh ssh-key add "$key.pub" --title "$title" || warn "Couldn't add the key to GitHub"
  fi
  if [[ $(git config --file "$local_config" commit.gpgsign 2>/dev/null || true) == true ]] &&
    [[ $keys != *signing* ]]; then
    gh ssh-key add "$key.pub" --type signing --title "$title" ||
      warn "Couldn't add the signing key. Run: gh auth refresh -h github.com -s admin:ssh_signing_key && ./install.sh ssh"
  fi
}

step_languages() {
  if has mise; then
    if mise install --yes; then
      ok "$(mise ls --current | wc -l | tr -d " ") tools from mise/config.toml"
    else
      warn "mise couldn't install everything. Run: ./install.sh languages"
    fi
  fi
}

# Muxy rewrites its settings files while running (window sizes, recent
# projects), which would replace a symlink. So they're copied, and only when
# missing: a new Mac gets this config, an existing one keeps its own.
step_muxy() {
  local dir="$HOME/Library/Application Support/Muxy 2" file
  mkdir -p "$dir"
  for file in settings.toml terminal.toml ghostty.conf server.toml; do
    if [[ ! -e $dir/$file ]]; then
      cp "muxy/$file" "$dir/$file"
      ok "$file"
    elif cmp -s "muxy/$file" "$dir/$file"; then
      ok "$file"
    else
      info "$file: keeping this Mac's version (differs from muxy/$file)"
    fi
  done
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

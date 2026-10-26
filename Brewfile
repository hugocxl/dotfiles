# Everything Homebrew installs. Apply with `brew bundle` (install.sh does this).
# See what's installed but missing from here with `brew bundle cleanup`.
# Yab (browser) isn't on Homebrew; install.sh downloads it directly.

# --- Taps --------------------------------------------------------------------
tap "muxy-app/tap"

# --- Shell -------------------------------------------------------------------
brew "pure"                     # minimal prompt (successor of the oh-my-zsh "refined" theme)
brew "zsh-autosuggestions"
brew "pam-reattach"             # Touch ID for sudo inside Muxy

# --- Git ---------------------------------------------------------------------
brew "git"
brew "gh"
brew "git-delta"                # syntax-highlighted diffs
brew "lazygit"

# --- Languages & runtimes ----------------------------------------------------
brew "mise"                     # node, pnpm, bun… (replaces nvm), see mise/config.toml
brew "uv"                       # python

# --- CLI essentials ----------------------------------------------------------
brew "bat"                      # cat with highlighting
brew "eza"                      # modern ls
brew "fd"
brew "ripgrep"
brew "jq"
brew "htop"
brew "yazi"                     # terminal file manager (icons off, see yazi/theme.toml)

# --- Fonts -------------------------------------------------------------------
cask "font-sf-mono"             # Muxy terminal font, see muxy/terminal.toml

# --- Apps --------------------------------------------------------------------
cask "1password"
cask "docker-desktop"
cask "google-drive"
cask "meetingbar"
cask "muxy-app/tap/muxy", trusted: true  # terminal; config in muxy/
cask "raycast"
cask "spotify"
cask "tableplus"

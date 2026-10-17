#!/usr/bin/env bash
# Security hardening that every new Mac should get. Safe to re-run.

set -uo pipefail
source "$(dirname "$0")/../lib/utils.sh"

title "Security"

# Touch ID for sudo. sudo_local survives macOS updates (unlike editing
# /etc/pam.d/sudo). pam_reattach makes it work inside tmux too.
if grep -q pam_tid /etc/pam.d/sudo_local 2>/dev/null; then
  ok "Touch ID for sudo"
elif ask "Use Touch ID for sudo?"; then
  reattach="$(brew_prefix)/lib/pam/pam_reattach.so"
  {
    echo "# Managed by dotfiles (macos/security.sh)"
    [[ -f $reattach ]] && echo "auth       optional       $reattach ignore_ssh"
    echo "auth       sufficient     pam_tid.so"
  } | sudo tee /etc/pam.d/sudo_local >/dev/null
  ok "Touch ID for sudo enabled"
fi

# Application firewall, with stealth mode (don't answer pings / port scans)
fw=/usr/libexec/ApplicationFirewall/socketfilterfw
if sudo "$fw" --getglobalstate | grep -q enabled; then
  ok "Firewall"
elif ask "Turn on the firewall?"; then
  sudo "$fw" --setglobalstate on >/dev/null
  sudo "$fw" --setstealthmode on >/dev/null
  ok "Firewall enabled (stealth mode)"
fi

# Require the password as soon as the screen locks
if [[ -t 0 && ${DOTFILES_YES:-0} != 1 ]] && ask "Require your password immediately after the screen locks?"; then
  info "sysadminctl will ask for your login password"
  if sysadminctl -screenLock immediate -password -; then
    ok "Password required immediately after lock"
  else
    warn "Couldn't set it; use System Settings → Lock Screen"
  fi
fi

# FileVault needs a restart and shows a recovery key, so only check it
if fdesetup status | grep -q "On"; then
  ok "FileVault"
else
  warn "FileVault is off. Turn it on in System Settings → Privacy & Security."
fi

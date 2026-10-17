# Shared helpers, sourced by install.sh and the macos/ scripts.
# Must stay compatible with the stock macOS bash 3.2 (no associative arrays).

DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"

if [[ -t 1 ]]; then
  BOLD=$'\033[1m' DIM=$'\033[2m' RED=$'\033[31m' GREEN=$'\033[32m'
  YELLOW=$'\033[33m' BLUE=$'\033[34m' RESET=$'\033[0m'
else
  BOLD='' DIM='' RED='' GREEN='' YELLOW='' BLUE='' RESET=''
fi

title() { printf '\n%s==>%s %s%s%s\n' "$BLUE" "$RESET" "$BOLD" "$*" "$RESET"; }
info()  { printf '  %s•%s %s\n' "$DIM" "$RESET" "$*"; }
ok()    { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn()  { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
die()   { printf '  %s✗%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }

has() { command -v "$1" >/dev/null 2>&1; }

# ask "Question?" [y|n] — yes/no prompt. With --yes (or no TTY) the default wins.
ask() {
  local question=$1 default=${2:-y} hint='[Y/n]' reply
  [[ $default == n ]] && hint='[y/N]'
  if [[ ${DOTFILES_YES:-0} == 1 || ! -t 0 ]]; then
    [[ $default == y ]]
    return
  fi
  read -r -p "  ${BOLD}?${RESET} $question $hint " reply
  [[ ${reply:-$default} =~ ^[Yy] ]]
}

# prompt "Question" default — free-text prompt, echoes the answer.
prompt() {
  local question=$1 default=${2:-} reply
  if [[ ${DOTFILES_YES:-0} == 1 || ! -t 0 ]]; then
    printf '%s' "$default"
    return
  fi
  read -r -p "  ${BOLD}?${RESET} $question${default:+ ($default)}: " reply
  printf '%s' "${reply:-$default}"
}

# backup <path> — move an existing file out of the way, keeping its relative path.
backup() {
  local target=$1 rel=${1#"$HOME"/}
  [[ -e $target || -L $target ]] || return 0
  mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  mv "$target" "$BACKUP_DIR/$rel"
  warn "moved existing $target to $BACKUP_DIR/$rel"
}

# link <repo-relative source> <target> — idempotent symlink into the repo.
link() {
  local src="$DOTFILES/$1" dst=$2
  if [[ -L $dst && $(readlink "$dst") == "$src" ]]; then
    ok "${dst/#$HOME/~}"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  backup "$dst"
  ln -s "$src" "$dst"
  ok "${dst/#$HOME/~} → $1"
}

# Keep the sudo timestamp fresh until the calling script exits.
sudo_keepalive() {
  sudo -v || die "Administrator access is required"
  while true; do
    sudo -n true
    sleep 50
    kill -0 "$$" || exit
  done 2>/dev/null &
}

brew_prefix() {
  if [[ $(uname -m) == arm64 ]]; then echo /opt/homebrew; else echo /usr/local; fi
}

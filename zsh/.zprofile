# Login shells only: set up PATH once, before .zshrc runs.

# Homebrew (Apple silicon first, Intel fallback)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Personal and tool-installed binaries. typeset -U drops duplicates.
typeset -U path
path=("$HOME/.local/bin" "$HOME/bin" "$HOME/.cargo/bin" $path)
# rustup is keg-only in Homebrew
[[ -n $HOMEBREW_PREFIX ]] && path=("$HOMEBREW_PREFIX/opt/rustup/bin" $path)

export EDITOR="code --wait"
export VISUAL="$EDITOR"

# Interactive shell config. No framework: plugins come from Homebrew.
# Machine-specific settings and secrets go in ~/.zshrc.local (not tracked).

# --- History -----------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS SHARE_HISTORY

# --- Options -----------------------------------------------------------------
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS INTERACTIVE_COMMENTS NO_BEEP

# Homebrew is normally set up in .zprofile, which only login shells read.
# Cover shells started without it so plugins and tools still load.
if [[ -z $HOMEBREW_PREFIX ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# --- Completion --------------------------------------------------------------
if [[ -n $HOMEBREW_PREFIX ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi
[[ -d $HOME/.zsh/completions ]] && fpath=("$HOME/.zsh/completions" $fpath)

autoload -Uz compinit
# Rebuild the completion cache at most once a day; it's the slowest part of startup.
_stale_dump=($HOME/.zcompdump(N.mh+24))
if (( $#_stale_dump )); then compinit; else compinit -C; fi
unset _stale_dump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# --- Prompt ------------------------------------------------------------------
autoload -Uz promptinit && promptinit
if (( ${prompt_themes[(Ie)pure]} )); then
  prompt pure
else
  PROMPT='%F{blue}%~%f %F{magenta}❯%f '
fi

# --- Tools -------------------------------------------------------------------
has() { (( $+commands[$1] )); }

has mise && eval "$(mise activate zsh)"

# Global packages from `pnpm add -g` and `bun add -g`
export PNPM_HOME="$HOME/Library/pnpm"
path=("$PNPM_HOME" "$HOME/.bun/bin" $path)

# --- Aliases -----------------------------------------------------------------
alias zshconfig='${EDITOR:-nano} ~/.zshrc'
alias dotfiles="cd ${${:-$HOME/.zshrc}:A:h:h}"
alias reload="exec zsh"

# Keep everything up to date
alias update="brew update && brew upgrade && mise upgrade"

if has eza; then
  alias ls="eza --group-directories-first"
  alias ll="eza -l --git --group-directories-first"
  alias la="eza -la --git --group-directories-first"
  alias lt="eza --tree --level=2"
fi

# Git
alias ga="git a"
alias gf="git f"
alias gls="git ls"
alias gst="git st"
alias gcm="git cm"
alias gps="git ps"
alias gpl="git pl"
alias gco="git co"
alias gcob="git cob"
alias gcp="git cp"
alias gs="git save"
alias gr="git reset"
alias gcl="git cl"
alias lg="lazygit"

# pnpm
alias px="pnpm"
alias pxi="px i"
alias pxb="px build"
alias pxd="px dev"
alias pxs="px start"
alias pxt="px test"

# --- Local overrides ---------------------------------------------------------
[[ -f $HOME/.zshrc.local ]] && source "$HOME/.zshrc.local"

# --- Plugins -----------------------------------------------------------------
if [[ -n $HOMEBREW_PREFIX ]]; then
  source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" 2>/dev/null
fi

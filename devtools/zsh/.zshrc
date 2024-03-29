# Export
export PATH="$PATH:$HOME/.local/bin"
export ZSH="$HOME/.oh-my-zsh"
export MANPATH="/usr/local/man:$MANPATH"
export PATH=/opt/homebrew/bin:$PATH
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
export PNPM_HOME="/Users/hugocxl/Library/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

# User configuration
ZSH_THEME="refined"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="dd.mm.yyyy"

# Plugins
plugins=(git)

# Aliases
alias zshconfig="open ~/.zshrc"
alias ohmyzsh="open ~/.oh-my-zsh"
alias ga="git a"
alias gf="git f"
alias gls="git ls"
alias gst="!git st"
alias gcm="git cm"
alias gps="git ps"
alias gpl="git pl"
alias gco="git co"
alias gcob="git cob"
alias gcp="git cp"
alias gs="git save"
alias gr="git reset"
alias gcl="git cl"
alias px="pnpm"
alias pxi="px i"
alias pxb="px build"
alias pxd="px dev"
alias pxs="px start"
alias pxt="px test"

# Setup
source $ZSH/oh-my-zsh.sh

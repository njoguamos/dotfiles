# Standalone Zsh configuration. No Oh My Zsh or machine-specific identity.
export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
export EDITOR="${EDITOR:-nano}"
export HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE
autoload -Uz compinit
compinit -i -d "$HOME/.zcompdump"

add_to_path() {
  [[ -d "$1" && ":$PATH:" != *":$1:"* ]] && export PATH="$1:$PATH"
}

add_to_path "$HOME/.local/bin"
add_to_path "$HOME/.composer/vendor/bin"
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"
  add_to_path "$BREW_PREFIX/opt/node@24/bin"
  # Homebrew Ruby is keg-only; prefer it and its gem command over macOS Ruby.
  add_to_path "$BREW_PREFIX/opt/ruby/bin"
  if [[ -x "$BREW_PREFIX/opt/ruby/bin/ruby" ]]; then
    add_to_path "$("$BREW_PREFIX/opt/ruby/bin/ruby" -r rubygems -e 'print Gem.bindir' 2>/dev/null)"
  fi
  [[ -r "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] \
    && source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Use the Bitwarden desktop SSH agent.
export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"

alias c='clear'
alias reloadshell='source ~/.zprofile'
alias bu='brew update && brew outdated'
alias gst='git status --short --branch'
alias gl='git log --oneline --decorate -12'
alias dotfiles='cd "$DOTFILES"'

if [[ -n "${BREW_PREFIX:-}" \
   && -r "$BREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme" \
   && -r "$DOTFILES/.p10k.zsh" ]]; then
  source "$BREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme"
  source "$DOTFILES/.p10k.zsh"
else
  PROMPT='%F{cyan}%1~%f %# '
fi


#!/bin/bash
set -u

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
ok=0
attention=0
optional=0

pass() { printf 'PASS       %s\n' "$*"; ok=$((ok + 1)); }
needs() { printf 'NEEDS WORK %s\n' "$*"; attention=$((attention + 1)); }
maybe() { printf 'OPTIONAL   %s\n' "$*"; optional=$((optional + 1)); }

printf 'Setup verification (%s)\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"

if [[ "$(uname -s)" == Darwin ]]; then pass "Running on macOS"; else needs "This repo targets macOS"; fi
if xcode-select -p >/dev/null 2>&1; then pass "Apple Command Line Tools"; else needs "Install Apple Command Line Tools"; fi

if command -v brew >/dev/null 2>&1; then
  pass "Homebrew available"
  if brew bundle check --file "$DOTFILES_DIR/Brewfile" >/dev/null 2>&1; then pass "Baseline Brewfile installed"; else needs "Run scripts/setup.sh to install baseline packages"; fi
  for cli in git gh; do
    if command -v "$cli" >/dev/null 2>&1; then pass "$cli command-line tool available"; else needs "Install or expose the $cli command-line tool"; fi
  done
else
  needs "Install Homebrew"
fi

if [[ -L "$HOME/.zshrc" && "$(readlink "$HOME/.zshrc")" == "$DOTFILES_DIR/.zshrc" ]]; then pass "~/.zshrc links to this repo"; else needs "Link the managed Zsh config with scripts/setup.sh"; fi
if [[ -f "$HOME/.config/dotfiles/agent" ]]; then
  agent="$(cat "$HOME/.config/dotfiles/agent")"
  case "$agent" in
    codex) [[ -d /Applications/ChatGPT.app || -d /Applications/Codex.app ]] && pass "Selected Codex desktop app" || needs "Install the selected Codex desktop app" ;;
    claude) [[ -d /Applications/Claude.app ]] && pass "Selected Claude desktop app" || needs "Install the selected Claude desktop app" ;;
    opencode) [[ -d /Applications/OpenCode.app ]] && pass "Selected OpenCode desktop app" || needs "Install the selected OpenCode desktop app" ;;
    *) needs "Unknown selected agent value in ~/.config/dotfiles/agent" ;;
  esac
else
  maybe "No AI app selection recorded; set one by rerunning bootstrap or setup.sh --agent …"
fi

if command -v op >/dev/null 2>&1; then
  pass "1Password CLI installed"
  if op whoami >/dev/null 2>&1; then pass "1Password CLI signed in"; else needs "Sign in to 1Password and enable its SSH Agent"; fi
else
  needs "Install 1Password CLI from the baseline"
fi

if [[ -n "${SSH_AUTH_SOCK:-}" && -S "$SSH_AUTH_SOCK" ]] && ssh-add -l >/dev/null 2>&1; then
  pass "SSH agent responds and has at least one key (key details hidden)"
else
  needs "Unlock 1Password and configure its SSH Agent; key paths and values stay local"
fi

if ssh -o BatchMode=yes -o ConnectTimeout=8 -T git@github.com 2>&1 | grep -qi 'successfully authenticated'; then
  pass "GitHub SSH authentication"
else
  needs "Add the 1Password public key to GitHub and configure ~/.ssh/config"
fi

if [[ "$(git config --global --get gpg.format 2>/dev/null || true)" == ssh \
   && "$(git config --global --get commit.gpgsign 2>/dev/null || true)" == true \
   && -n "$(git config --global --get user.signingkey 2>/dev/null || true)" ]]; then
  pass "Git SSH commit signing configured (identity hidden)"
else
  needs "Configure Git SSH signing with the public key from 1Password"
fi
signers_file="$(git config --global --get gpg.ssh.allowedSignersFile 2>/dev/null || true)"
if [[ -n "$signers_file" && -f "$signers_file" ]] && git verify-commit HEAD >/dev/null 2>&1; then
  pass "Local verification of the current SSH-signed commit"
else
  needs "Create a local allowed_signers file and configure gpg.ssh.allowedSignersFile"
fi

if [[ -d "/Applications/Little Snitch.app" ]]; then pass "Manual app present: Little Snitch"; else maybe "Manual app absent: Little Snitch (install only if wanted)"; fi

printf '\nSummary: %d passed, %d need attention, %d optional\n' "$ok" "$attention" "$optional"
if (( attention > 0 )); then exit 1; fi
exit 0

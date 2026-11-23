#!/bin/bash
set -u

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
ok=0
attention=0
optional=0
skipped=0

pass() { printf 'PASS       %s\n' "$*"; ok=$((ok + 1)); }
needs() { printf 'NEEDS WORK %s\n' "$*"; attention=$((attention + 1)); }
skip() { printf 'SKIPPED    %s\n' "$*"; skipped=$((skipped + 1)); }
maybe() { printf 'OPTIONAL   %s\n' "$*"; optional=$((optional + 1)); }

printf 'Setup verification (%s)\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"

if [[ "$(uname -s)" == Darwin ]]; then pass "Running on macOS"; else needs "This repo targets macOS"; fi
if xcode-select -p >/dev/null 2>&1; then pass "Apple Command Line Tools"; else needs "Install Apple Command Line Tools"; fi

if command -v brew >/dev/null 2>&1; then
  pass "Homebrew available"
  source "$DOTFILES_DIR/scripts/package-plan.sh"
  if build_package_plan < "$DOTFILES_DIR/Brewfile"; then
    report_preserved_casks
    if brew bundle check --no-upgrade --file "$BUNDLE_FILE" >/dev/null 2>&1; then
      pass "Required packages in this Mac’s Homebrew plan are installed"
    else
      needs "Preview scripts/setup.sh --preview to review missing packages"
    fi
  else
    needs "Could not build the Homebrew package plan"
  fi
  for cli in git gh; do
    if command -v "$cli" >/dev/null 2>&1; then pass "$cli command-line tool available"; else needs "Install or expose the $cli command-line tool"; fi
  done
  ruby_gem="$(brew --prefix)/opt/ruby/bin/gem"
  if [[ -x "$ruby_gem" ]] && "$ruby_gem" list --local --exact --installed kamal >/dev/null 2>&1; then
    pass "Kamal gem installed for Homebrew Ruby"
  else
    needs "Install Kamal for Homebrew Ruby with the approved setup"
  fi
else
  needs "Install Homebrew"
fi

if [[ -L "$HOME/.zshrc" && "$(readlink "$HOME/.zshrc")" == "$DOTFILES_DIR/.zshrc" ]]; then pass "~/.zshrc links to this repo"; else needs "Link the managed Zsh config with scripts/setup.sh"; fi
spotlight_shortcut="$(defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys 2>/dev/null \
  | awk '/^[[:space:]]*64 =/ { in_spotlight=1 } /^[[:space:]]*[0-9]+ =/ && $1 != "64" { in_spotlight=0 } in_spotlight && /enabled =/ { print $3; exit }')"
if [[ "$spotlight_shortcut" == "0;" ]]; then
  pass "Spotlight ⌘Space shortcut is disabled"
  maybe "Press ⌘Space to confirm Raycast opens"
elif [[ -z "$spotlight_shortcut" ]]; then
  needs "Spotlight shortcut state unknown. Check Keyboard Shortcuts in System Settings"
else
  needs "Disable Spotlight ⌘Space in System Settings so Raycast can use it"
fi
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

if [[ -d /Applications/Bitwarden.app ]]; then
  pass "Bitwarden desktop app present"
  maybe "Confirm Bitwarden is signed in and its SSH agent is enabled"
else
  needs "Install Bitwarden from the baseline and sign in"
fi

agent_ready=0
if [[ -n "${SSH_AUTH_SOCK:-}" && -S "$SSH_AUTH_SOCK" ]] && ssh-add -l >/dev/null 2>&1; then
  agent_ready=1
  pass "SSH agent responds and has at least one key (key details hidden)"
else
  needs "Unlock Bitwarden and configure its SSH Agent; key paths and values stay local"
fi

if (( agent_ready == 0 )); then
  skip "GitHub SSH authentication. Unlock Bitwarden and rerun verification."
elif ssh -o StrictHostKeyChecking=yes -o UpdateHostKeys=no -o BatchMode=yes -o ConnectTimeout=8 -T git@github.com 2>&1 | grep -qi 'successfully authenticated'; then
  pass "GitHub SSH authentication"
else
  needs "GitHub SSH check failed. Check connectivity, host trust, and the registered public key"
fi

if [[ "$(git config --global --get gpg.format 2>/dev/null || true)" == ssh \
   && "$(git config --global --get commit.gpgsign 2>/dev/null || true)" == true \
   && -n "$(git config --global --get user.signingkey 2>/dev/null || true)" ]]; then
  pass "Git SSH commit signing configured (identity hidden)"
else
  needs "Configure Git SSH signing with the public key from Bitwarden"
fi
signing_program="$(git config --get gpg.ssh.program 2>/dev/null || true)"
if [[ "$signing_program" == *1Password* || "$signing_program" == *1password* || "$signing_program" == *op-ssh-sign* ]]; then
  needs "Git still uses the 1Password SSH signing program; configure Bitwarden signing"
elif [[ -n "$signing_program" ]]; then
  maybe "Git uses a custom SSH signing program; confirm it works with Bitwarden"
else
  pass "Git uses the default OpenSSH signing program"
fi
signers_file="$(git config --global --path --get gpg.ssh.allowedSignersFile 2>/dev/null || true)"
if [[ -z "$signers_file" || ! -r "$signers_file" ]]; then
  needs "Configure a readable local Git allowed-signers file"
elif ! git -C "$DOTFILES_DIR" cat-file commit HEAD 2>/dev/null | awk '/^$/{exit} /^gpgsig -----BEGIN SSH SIGNATURE-----$/{found=1} END{exit !found}'; then
  skip "The dotfiles HEAD has no SSH signature. Verify a known SSH-signed commit."
elif git -C "$DOTFILES_DIR" verify-commit HEAD >/dev/null 2>&1; then
  pass "Local verification of the current SSH-signed commit"
else
  needs "HEAD has an SSH signature that could not be verified. Check the signer entry and public key"
fi

if brew list --cask lulu >/dev/null 2>&1 && [[ -d "/Applications/LuLu.app" ]]; then
  pass "LuLu installed from Homebrew"
else
  needs "Install LuLu from the Homebrew manifest"
fi
if [[ -d "/Applications/Little Snitch.app" ]]; then
  maybe "Little Snitch is still present; remove it with the vendor-supported Finder method before enabling LuLu"
else
  pass "Little Snitch not present"
fi
if [[ -d "/Applications/Android Studio.app" ]]; then maybe "Optional app present: Android Studio"; else maybe "Optional app absent: Android Studio"; fi
if [[ -d "/Applications/Xcode.app" ]]; then maybe "Optional app present: full Xcode"; else maybe "Optional app absent: full Xcode"; fi

printf '\nSummary: %d passed, %d need attention, %d optional, %d skipped\n' "$ok" "$attention" "$optional" "$skipped"
if (( attention > 0 )); then exit 1; fi
exit 0

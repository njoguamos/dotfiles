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
  BUNDLE_FILE="$DOTFILES_DIR/Brewfile"
  BUNDLE_TMP=""
  SKIP_ONEDRIVE_CASK=0
  SKIP_BRAVE_CASK=0
  SKIP_1PASSWORD_CASK=0
  SKIP_RAYCAST_CASK=0
  if [[ -d "/Applications/OneDrive.app" ]] && ! brew list --cask onedrive >/dev/null 2>&1; then SKIP_ONEDRIVE_CASK=1; fi
  if [[ -d "/Applications/Brave Browser.app" ]] && ! brew list --cask brave-browser >/dev/null 2>&1; then SKIP_BRAVE_CASK=1; fi
  if [[ -d "/Applications/1Password.app" ]] && ! brew list --cask 1password >/dev/null 2>&1; then SKIP_1PASSWORD_CASK=1; fi
  if [[ -d "/Applications/Raycast.app" ]] && ! brew list --cask raycast >/dev/null 2>&1; then SKIP_RAYCAST_CASK=1; fi
  if (( SKIP_ONEDRIVE_CASK == 1 || SKIP_BRAVE_CASK == 1 || SKIP_1PASSWORD_CASK == 1 || SKIP_RAYCAST_CASK == 1 )); then
    BUNDLE_TMP="$(mktemp "${TMPDIR:-/tmp}/dotfiles-Brewfile.XXXXXX")"
    awk -v skip_onedrive="$SKIP_ONEDRIVE_CASK" -v skip_brave="$SKIP_BRAVE_CASK" \
      -v skip_1password="$SKIP_1PASSWORD_CASK" -v skip_raycast="$SKIP_RAYCAST_CASK" \
      '$0 == "cask \"onedrive\"" && skip_onedrive { next }
       $0 == "cask \"brave-browser\"" && skip_brave { next }
       $0 == "cask \"1password\"" && skip_1password { next }
       $0 == "cask \"raycast\"" && skip_raycast { next }
       { print }' "$DOTFILES_DIR/Brewfile" > "$BUNDLE_TMP"
    BUNDLE_FILE="$BUNDLE_TMP"
  fi
  if brew bundle check --file "$BUNDLE_FILE" >/dev/null 2>&1; then
    pass "Baseline Homebrew manifest installed"
    if [[ "$SKIP_ONEDRIVE_CASK" == 1 ]]; then maybe "Existing OneDrive app left unmanaged to protect its current sync settings"; fi
    if [[ "$SKIP_BRAVE_CASK" == 1 ]]; then maybe "Existing Brave installation left unmanaged"; fi
    if [[ "$SKIP_1PASSWORD_CASK" == 1 ]]; then maybe "Existing 1Password installation left unmanaged"; fi
    if [[ "$SKIP_RAYCAST_CASK" == 1 ]]; then maybe "Existing Raycast installation left unmanaged"; fi
  else
    needs "Run scripts/setup.sh to install baseline packages"
  fi
  [[ -z "$BUNDLE_TMP" ]] || rm -f "$BUNDLE_TMP"
  for cli in git gh; do
    if command -v "$cli" >/dev/null 2>&1; then pass "$cli command-line tool available"; else needs "Install or expose the $cli command-line tool"; fi
  done
else
  needs "Install Homebrew"
fi

if [[ -L "$HOME/.zshrc" && "$(readlink "$HOME/.zshrc")" == "$DOTFILES_DIR/.zshrc" ]]; then pass "~/.zshrc links to this repo"; else needs "Link the managed Zsh config with scripts/setup.sh"; fi
spotlight_shortcut="$(defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys 2>/dev/null \
  | awk '/^[[:space:]]*64 =/ { in_spotlight=1 } /^[[:space:]]*[0-9]+ =/ && $1 != "64" { in_spotlight=0 } in_spotlight && /enabled =/ { print $3; exit }')"
if [[ "$spotlight_shortcut" == "0;" ]]; then
  pass "Spotlight ⌘Space shortcut is disabled for Raycast"
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

printf '\nSummary: %d passed, %d need attention, %d optional\n' "$ok" "$attention" "$optional"
if (( attention > 0 )); then exit 1; fi
exit 0

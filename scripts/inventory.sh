#!/bin/bash
set -Eeuo pipefail

section() { printf '\n## %s\n' "$*"; }
has() { command -v "$1" >/dev/null 2>&1; }

section "System"
if [[ "$(uname -s)" == Darwin ]]; then
  printf 'macOS: %s (%s)\n' "$(sw_vers -productVersion)" "$(uname -m)"
  printf 'Command Line Tools: '
  if xcode-select -p >/dev/null 2>&1; then echo installed; else echo missing; fi
else
  printf 'OS: %s (%s)\n' "$(uname -s)" "$(uname -m)"
fi
printf 'Login shell: %s\n' "${SHELL##*/}"

section "Homebrew"
if has brew; then
  brew --version | head -n 1
  DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
  export HOMEBREW_NO_AUTO_UPDATE=1
  if ! ruby "$DOTFILES_DIR/scripts/package-inventory.rb" "$DOTFILES_DIR/Brewfile"; then
    echo "Package and app comparison unavailable."
  fi
else
  echo "Not installed"
  if [[ -d /Applications ]]; then
    find /Applications -type d -name '*.app' -prune -print | sort
  fi
fi

section "Selected macOS preferences (observed only)"
for key in autohide orientation tilesize show-recents; do
  value="$(defaults read com.apple.dock "$key" 2>/dev/null || true)"
  if [[ -n "$value" ]]; then printf 'Dock %s: %s\n' "$key" "$value"; fi
done
value="$(defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking 2>/dev/null || true)"
if [[ -n "$value" ]]; then printf 'Trackpad Clicking: %s\n' "$value"; fi
value="$(defaults -currentHost read NSGlobalDomain com.apple.mouse.tapBehavior 2>/dev/null || true)"
if [[ -n "$value" ]]; then printf 'Current-host tap behavior: %s\n' "$value"; fi
if defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys 2>/dev/null \
  | awk '/^[[:space:]]*64 =/ { target=64 } /^[[:space:]]*[0-9]+ =/ && $1 != "64" { target=0 } target && /enabled =/ { print "Spotlight ⌘Space shortcut enabled: " $3; target=0 }'; then
  :
fi

section "Agent clients"
for app in ChatGPT Codex Claude OpenCode; do
  if [[ -d "/Applications/$app.app" ]]; then printf '%s: installed\n' "$app"; fi
done
for cli in codex claude opencode; do
  if has "$cli"; then printf '%s CLI: installed\n' "$cli"; fi
done

section "1Password and SSH (status only)"
if has op; then
  echo "1Password CLI: installed"
  if op whoami >/dev/null 2>&1; then echo "1Password CLI session: signed in"; else echo "1Password CLI session: not signed in"; fi
else
  echo "1Password CLI: missing"
fi
if [[ -n "${SSH_AUTH_SOCK:-}" && -S "$SSH_AUTH_SOCK" ]]; then
  echo "SSH agent socket: available (path hidden)"
else
  echo "SSH agent socket: not available"
fi
if has ssh-add && ssh-add -l >/dev/null 2>&1; then echo "SSH agent key listing: available (key details hidden)"; else echo "SSH agent key listing: unavailable or empty"; fi

section "Git signing (values hidden)"
for setting in user.name user.email gpg.format user.signingkey commit.gpgsign; do
  value="$(git config --global --get "$setting" 2>/dev/null || true)"
  if [[ -n "$value" ]]; then printf '%s: configured\n' "$setting"; else printf '%s: missing\n' "$setting"; fi
done

section "Manual app checks"
if [[ -d "/Applications/LuLu.app" ]]; then echo "LuLu: installed"; else echo "LuLu: not detected"; fi
if [[ -d "/Applications/Little Snitch.app" ]]; then echo "Legacy firewall app present: Little Snitch"; fi

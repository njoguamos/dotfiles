#!/bin/bash
set -Eeuo pipefail
umask 077

REPO_URL="https://github.com/njoguamos/dotfiles.git"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

say() { printf '\n==> %s\n' "$*"; }
fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == Darwin ]] || fail "This setup is for macOS."
[[ -r /dev/tty && -w /dev/tty ]] || fail "Run this command from Terminal so it can ask which AI app to install."

if ! xcode-select -p >/dev/null 2>&1; then
  say "Installing Apple's Command Line Tools"
  xcode-select --install || true
  fail "Finish the Command Line Tools installation, then rerun the bootstrap command."
fi

say "Choose the AI app to use with this setup"
printf '  1) Codex / ChatGPT desktop (default)\n  2) Claude\n  3) OpenCode\n'
printf 'Select 1-3 [1]: '
IFS= read -r choice </dev/tty || choice=""
case "${choice:-1}" in
  1) agent="codex" ;;
  2) agent="claude" ;;
  3) agent="opencode" ;;
  *) fail "Choose 1, 2, or 3." ;;
esac

if ! command -v brew >/dev/null 2>&1; then
  say "Installing Homebrew"
  installer="$(mktemp -t dotfiles-homebrew-install.XXXXXX)"
  trap 'rm -f "$installer"' EXIT
  curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 \
    https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"
  /bin/bash "$installer"
  rm -f "$installer"
  trap - EXIT
fi

if ! command -v brew >/dev/null 2>&1; then
  for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$brew_path" ]]; then
      eval "$("$brew_path" shellenv)"
      break
    fi
  done
fi
command -v brew >/dev/null 2>&1 || fail "Homebrew is not available in this shell. Open a new Terminal and rerun bootstrap."

if [[ -d "$DOTFILES_DIR/.git" ]]; then
  say "Using existing checkout at $DOTFILES_DIR"
elif [[ -e "$DOTFILES_DIR" ]]; then
  fail "$DOTFILES_DIR exists but is not a Git checkout. Move it aside or set DOTFILES_DIR to another path."
else
  say "Cloning dotfiles into $DOTFILES_DIR"
  git clone --depth 1 "$REPO_URL" "$DOTFILES_DIR"
fi

state_dir="$HOME/.config/dotfiles"
mkdir -p "$state_dir"
[[ ! -L "$state_dir/agent" ]] || fail "Refusing to overwrite a symlink at $state_dir/agent."
state_tmp="$(mktemp "$state_dir/.agent.XXXXXX")"
printf '%s\n' "$agent" > "$state_tmp"
chmod 600 "$state_tmp"
mv -f "$state_tmp" "$state_dir/agent"

# Install only the selected AI client here. The agent will inspect and review
# the repository's package manifest before running the broader setup.
case "$agent" in
  codex)
    if [[ ! -d /Applications/ChatGPT.app && ! -d /Applications/Codex.app ]]; then
      say "Installing ChatGPT desktop (includes Codex)"
      brew install --cask chatgpt
    fi
    app_name="ChatGPT"
    [[ -d /Applications/ChatGPT.app || ! -d /Applications/Codex.app ]] || app_name="Codex"
    ;;
  claude)
    if [[ ! -d /Applications/Claude.app ]]; then
      say "Installing Claude desktop"
      brew install --cask claude
    fi
    app_name="Claude"
    ;;
  opencode)
    if [[ ! -d /Applications/OpenCode.app ]]; then
      say "Installing OpenCode desktop"
      brew install --cask opencode-desktop
    fi
    app_name="OpenCode"
    ;;
esac

printf '\nOpen %s now to inspect the setup and continue there? [Y/n] ' "$agent"
IFS= read -r open_now </dev/tty || open_now=""
if [[ ! "$open_now" =~ ^[Nn]$ ]]; then
  open -a "$app_name" "$DOTFILES_DIR" || say "Open $DOTFILES_DIR in $app_name to continue."
fi

say "Bootstrap complete. The selected AI app is installed; review the repo in that app, then follow AGENTS.md and SETUP.md."

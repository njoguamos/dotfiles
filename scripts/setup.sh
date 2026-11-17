#!/bin/bash
set -Eeuo pipefail
umask 077

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
AGENT=""
APPROVED=0
STATE_DIR="$HOME/.config/dotfiles"
STATE_FILE="$STATE_DIR/agent"
if [[ -L "$STATE_FILE" ]]; then
  echo "Refusing to read a symlink at $STATE_FILE." >&2
  exit 1
fi

usage() { printf 'Usage: %s [--agent codex|claude|opencode] [--yes]\n' "$0"; }
while (($#)); do
  case "$1" in
    --agent)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      AGENT="$2"
      shift 2
      ;;
    --yes) APPROVED=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

if [[ -n "$AGENT" ]]; then
  case "$AGENT" in codex|claude|opencode) ;; *) echo "Unknown agent: $AGENT" >&2; exit 2 ;; esac
elif [[ -f "$HOME/.config/dotfiles/agent" ]]; then
  AGENT="$(cat "$HOME/.config/dotfiles/agent")"
  case "$AGENT" in codex|claude|opencode) ;; *) echo "Unknown selected agent in ~/.config/dotfiles/agent" >&2; exit 2 ;; esac
fi

command -v brew >/dev/null 2>&1 || { echo "Homebrew is required. Run bootstrap.sh first." >&2; exit 1; }
BREW_BIN="$(command -v brew)"
SKIP_ONEDRIVE_CASK=0
SKIP_BRAVE_CASK=0
SKIP_1PASSWORD_CASK=0
SKIP_RAYCAST_CASK=0
if [[ -d "/Applications/OneDrive.app" ]] && ! "$BREW_BIN" list --cask onedrive >/dev/null 2>&1; then
  SKIP_ONEDRIVE_CASK=1
fi
if [[ -d "/Applications/Brave Browser.app" ]] && ! "$BREW_BIN" list --cask brave-browser >/dev/null 2>&1; then
  SKIP_BRAVE_CASK=1
fi
if [[ -d "/Applications/1Password.app" ]] && ! "$BREW_BIN" list --cask 1password >/dev/null 2>&1; then
  SKIP_1PASSWORD_CASK=1
fi
if [[ -d "/Applications/Raycast.app" ]] && ! "$BREW_BIN" list --cask raycast >/dev/null 2>&1; then
  SKIP_RAYCAST_CASK=1
fi

ZSHRC="$HOME/.zshrc"
if [[ -L "$ZSHRC" ]]; then
  current_target="$(readlink "$ZSHRC")"
  case "$current_target" in
    "$DOTFILES_DIR/.zshrc") ;;
    *) echo "Existing ~/.zshrc symlink points elsewhere ($current_target); leaving it untouched." >&2; exit 1 ;;
  esac
elif [[ -e "$ZSHRC" && ! -f "$ZSHRC" ]]; then
  echo "~/.zshrc exists but is not a regular file; leaving it untouched." >&2
  exit 1
fi
if (( APPROVED == 0 )); then
  [[ -r /dev/tty && -w /dev/tty ]] || { echo "Run setup interactively, or have the agent obtain your approval before using --yes." >&2; exit 1; }
  printf 'The following required Homebrew manifest will be applied:\n\n'
  cat "$DOTFILES_DIR/Brewfile"
  if (( SKIP_ONEDRIVE_CASK == 1 )); then
    printf '\nOneDrive is already installed outside Homebrew. Its cask will be skipped on this Mac to avoid reinstalling the active sync app.\n'
  fi
  if (( SKIP_BRAVE_CASK == 1 )); then
    printf 'Brave is already installed outside Homebrew. Its cask will be skipped on this Mac to avoid replacing the current browser app.\n'
  fi
  if (( SKIP_1PASSWORD_CASK == 1 )); then
    printf '1Password is already installed outside Homebrew. Its cask will be skipped on this Mac to preserve the current installation.\n'
  fi
  if (( SKIP_RAYCAST_CASK == 1 )); then
    printf 'Raycast is already installed outside Homebrew. Its cask will be skipped on this Mac to preserve the current installation.\n'
  fi
  printf '\nThis installs packages and may request administrator approval. Apply the manifest and link the managed Zsh config? [y/N] '
  IFS= read -r answer </dev/tty || answer=""
  [[ "$answer" =~ ^[Yy]$ ]] || { echo "Setup cancelled."; exit 0; }
else
  echo "Using the approval granted in the agent conversation."
fi

echo "Installing required Homebrew packages from Brewfile..."
BUNDLE_FILE="$DOTFILES_DIR/Brewfile"
BUNDLE_TMP=""
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
  trap '[[ -z "${BUNDLE_TMP:-}" ]] || rm -f "$BUNDLE_TMP"' EXIT
fi
"$BREW_BIN" bundle --file "$BUNDLE_FILE"

if [[ -n "$AGENT" ]]; then
  case "$AGENT" in
    codex)
      if [[ ! -d /Applications/ChatGPT.app && ! -d /Applications/Codex.app ]]; then
        echo "Installing the ChatGPT desktop app (includes Codex)..."
        "$BREW_BIN" install --cask chatgpt
      fi
      ;;
    claude)
      if [[ ! -d /Applications/Claude.app ]]; then
        echo "Installing Claude desktop..."
        "$BREW_BIN" install --cask claude
      fi
      ;;
    opencode)
      if [[ ! -d /Applications/OpenCode.app ]]; then
        echo "Installing OpenCode desktop..."
        "$BREW_BIN" install --cask opencode-desktop
      fi
      ;;
  esac
  mkdir -p "$STATE_DIR"
  state_tmp="$(mktemp "$STATE_DIR/.agent.XXXXXX")"
  printf '%s\n' "$AGENT" > "$state_tmp"
  chmod 600 "$state_tmp"
  mv -f "$state_tmp" "$STATE_FILE"
fi

# Add Homebrew's shell setup once; preserve the user's other profile content.
PROFILE="$HOME/.zprofile"
if [[ -L "$PROFILE" ]]; then
  BREW_BIN_ESCAPED="$(printf '%q' "$BREW_BIN")"
  printf 'Leaving symlinked ~/.zprofile untouched. Add this line to its target if needed: eval "$(%s shellenv)"\n' "$BREW_BIN_ESCAPED"
else
  touch "$PROFILE"
  if ! grep -q 'BEGIN dotfiles Homebrew shellenv' "$PROFILE"; then
    BREW_BIN_ESCAPED="$(printf '%q' "$BREW_BIN")"
    {
      printf '\n# BEGIN dotfiles Homebrew shellenv\n'
      printf 'eval "$(%s shellenv)"\n' "$BREW_BIN_ESCAPED"
      printf '# END dotfiles Homebrew shellenv\n'
    } >> "$PROFILE"
  fi
fi

# Preserve an existing file, but stop rather than hijack a different symlink manager.
if [[ -L "$ZSHRC" ]]; then
  :
elif [[ -e "$ZSHRC" ]]; then
  backup="$ZSHRC.backup.$(date +%Y%m%d-%H%M%S)"
  mv "$ZSHRC" "$backup"
  echo "Backed up existing ~/.zshrc to $backup"
  if ! ln -s "$DOTFILES_DIR/.zshrc" "$ZSHRC"; then
    mv "$backup" "$ZSHRC"
    echo "Could not link ~/.zshrc; restored the original file." >&2
    exit 1
  fi
else
  ln -s "$DOTFILES_DIR/.zshrc" "$ZSHRC"
fi

echo "Setup complete. Open a new Terminal window to load the shell configuration."
echo "Next: follow SETUP.md for 1Password SSH, Git signing, manual apps, and verification."

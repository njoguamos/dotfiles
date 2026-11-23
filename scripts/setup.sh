#!/bin/bash
set -Eeuo pipefail
umask 077

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
AGENT=""
APPROVED=0
PREVIEW_ONLY=0
STATE_DIR="$HOME/.config/dotfiles"
STATE_FILE="$STATE_DIR/agent"
if [[ -L "$STATE_FILE" ]]; then
  echo "Refusing to read a symlink at $STATE_FILE." >&2
  exit 1
fi

usage() { printf 'Usage: %s [--agent codex|claude|opencode] [--preview|--yes]\n' "$0"; }
while (($#)); do
  case "$1" in
    --agent)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      AGENT="$2"
      shift 2
      ;;
    --preview) PREVIEW_ONLY=1; shift ;;
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
export HOMEBREW_NO_AUTO_UPDATE=1
source "$DOTFILES_DIR/scripts/package-plan.sh"
build_package_plan < "$DOTFILES_DIR/Brewfile"

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
printf 'Homebrew manifest for this Mac:\n\n'
cat "$BUNDLE_FILE"
report_preserved_casks
printf '\nMissing Homebrew requirements:\n'
if "$BREW_BIN" bundle check --no-upgrade --verbose --file "$BUNDLE_FILE"; then
  printf 'All requirements in this Homebrew plan are installed.\n'
fi
printf '\nShell: add Homebrew to ~/.zprofile when writable and link ~/.zshrc, backing up an existing regular file.\n'
printf 'Ruby gems: install Kamal with Homebrew Ruby if it is missing.\n'
printf 'Selected AI client: %s\n' "${AGENT:-none}"
if (( PREVIEW_ONLY == 1 )); then exit 0; fi
if (( APPROVED == 0 )); then
  [[ -r /dev/tty && -w /dev/tty ]] || { echo "Use an interactive terminal or approve the plan in chat." >&2; exit 1; }
  printf '\nThis installs packages and may request administrator approval. Apply the manifest and link the managed Zsh config? [y/N] '
  IFS= read -r answer </dev/tty || answer=""
  [[ "$answer" =~ ^[Yy]$ ]] || { echo "Setup cancelled."; exit 0; }
else
  echo "Using the approval granted in the agent conversation."
fi

echo "Installing required Homebrew packages from Brewfile..."
"$BREW_BIN" bundle install --no-upgrade --file "$BUNDLE_FILE"

BREW_RUBY_BIN="$("$BREW_BIN" --prefix)/opt/ruby/bin"
if [[ ! -x "$BREW_RUBY_BIN/gem" ]]; then
  echo "Homebrew Ruby's gem command is unavailable; cannot install Kamal." >&2
  exit 1
fi
if "$BREW_RUBY_BIN/gem" list --local --exact --installed kamal >/dev/null; then
  echo "Kamal is already installed for Homebrew Ruby."
else
  echo "Installing Kamal for Homebrew Ruby..."
  "$BREW_RUBY_BIN/gem" install kamal --no-document
fi

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
echo "Next: follow SETUP.md for Bitwarden SSH, Git signing, manual apps, and verification."

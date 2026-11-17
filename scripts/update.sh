#!/bin/bash
set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
command -v brew >/dev/null 2>&1 || { echo "Homebrew is required." >&2; exit 1; }
PREVIEW_ONLY=0
APPROVED=0
EXPECTED_UPSTREAM=""
usage() { printf 'Usage: %s [--preview] [--yes --expected-upstream SHA]\n' "$0"; }
while (($#)); do
  case "$1" in
    --preview) PREVIEW_ONLY=1; shift ;;
    --yes) APPROVED=1; shift ;;
    --expected-upstream)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      EXPECTED_UPSTREAM="$2"
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
if (( APPROVED == 1 )) && [[ -z "$EXPECTED_UPSTREAM" ]]; then
  echo "--yes requires --expected-upstream so only the reviewed commit can be applied." >&2
  exit 2
fi
if (( PREVIEW_ONLY == 1 && APPROVED == 1 )); then
  echo "Choose --preview or --yes, not both." >&2
  exit 2
fi

echo "This updates the dotfiles checkout and packages declared in Brewfile. It does not change macOS settings."
if [[ -n "$(git -C "$DOTFILES_DIR" status --porcelain)" ]]; then
  echo "The dotfiles checkout has local changes. Review or commit them before updating." >&2
  exit 1
fi

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
  if (( SKIP_ONEDRIVE_CASK == 1 )); then echo "OneDrive is already installed outside Homebrew; its cask will be skipped to protect the current sync setup."; fi
  if (( SKIP_BRAVE_CASK == 1 )); then echo "Brave is already installed outside Homebrew; its cask will be skipped to preserve the current browser app."; fi
  if (( SKIP_1PASSWORD_CASK == 1 )); then echo "1Password is already installed outside Homebrew; its cask will be skipped to preserve the current installation."; fi
  if (( SKIP_RAYCAST_CASK == 1 )); then echo "Raycast is already installed outside Homebrew; its cask will be skipped to preserve the current installation."; fi
  trap '[[ -z "${BUNDLE_TMP:-}" ]] || rm -f "$BUNDLE_TMP"' EXIT
fi

git -C "$DOTFILES_DIR" fetch origin
UPSTREAM="$(git -C "$DOTFILES_DIR" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}')"
brew update
UPSTREAM_SHA="$(git -C "$DOTFILES_DIR" rev-parse "$UPSTREAM^{commit}")"
if [[ -n "$EXPECTED_UPSTREAM" && "$UPSTREAM_SHA" != "$EXPECTED_UPSTREAM" ]]; then
  echo "The upstream changed since preview. Review the new diff before applying it." >&2
  exit 1
fi
printf '\nIncoming dotfiles commits:\n'
git -C "$DOTFILES_DIR" log --oneline "HEAD..$UPSTREAM"
printf '\nIncoming file summary:\n'
git -C "$DOTFILES_DIR" diff --stat "HEAD..$UPSTREAM"
printf '\nFull incoming diff for review:\n'
git -C "$DOTFILES_DIR" --no-pager diff --color=never "HEAD..$UPSTREAM"

printf '\nOutdated packages declared in Brewfile:\n'
while IFS= read -r package; do
  if [[ -n "$package" ]]; then brew outdated --formula "$package" || true; fi
done < <(brew bundle list --file "$DOTFILES_DIR/Brewfile" --formula)
while IFS= read -r package; do
  if [[ -n "$package" ]]; then brew outdated --cask --greedy "$package" || true; fi
done < <(brew bundle list --file "$DOTFILES_DIR/Brewfile" --cask)

printf '\nReviewed upstream commit: %s\n' "$UPSTREAM_SHA"
if (( PREVIEW_ONLY == 1 )); then exit 0; fi
if (( APPROVED == 0 )); then
  printf 'Continue? [y/N] '
  [[ -r /dev/tty ]] || { echo "Run interactively, or preview in the agent and approve that exact commit." >&2; exit 1; }
  IFS= read -r answer </dev/tty || answer=""
  [[ "$answer" =~ ^[Yy]$ ]] || { echo "Update cancelled."; exit 0; }
fi

git -C "$DOTFILES_DIR" merge --ff-only "$UPSTREAM_SHA"
brew bundle upgrade --file "$BUNDLE_FILE"

echo "Update complete. Run scripts/verify.sh to review setup health."

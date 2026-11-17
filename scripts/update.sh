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

source "$DOTFILES_DIR/scripts/package-plan.sh"
export HOMEBREW_NO_AUTO_UPDATE=1

git -C "$DOTFILES_DIR" fetch origin
UPSTREAM="$(git -C "$DOTFILES_DIR" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}')"
UPSTREAM_SHA="$(git -C "$DOTFILES_DIR" rev-parse "$UPSTREAM^{commit}")"
if [[ -n "$EXPECTED_UPSTREAM" && "$UPSTREAM_SHA" != "$EXPECTED_UPSTREAM" ]]; then
  echo "The upstream changed since preview. Review the new diff before applying it." >&2
  exit 1
fi
git -C "$DOTFILES_DIR" merge-base --is-ancestor HEAD "$UPSTREAM_SHA" || {
  echo "The checkout cannot fast-forward to the reviewed commit." >&2
  exit 1
}
incoming_manifest="$(git -C "$DOTFILES_DIR" show "$UPSTREAM_SHA:Brewfile")"
build_package_plan <<< "$incoming_manifest"
printf '\nIncoming Homebrew plan for this Mac:\n'
cat "$BUNDLE_FILE"
report_preserved_casks

printf '\nIncoming dotfiles commits:\n'
git -C "$DOTFILES_DIR" log --oneline "HEAD..$UPSTREAM_SHA"
printf '\nIncoming file summary:\n'
git -C "$DOTFILES_DIR" diff --stat "HEAD..$UPSTREAM_SHA"
printf '\nFull incoming diff for review:\n'
git -C "$DOTFILES_DIR" --no-pager diff --color=never "HEAD..$UPSTREAM_SHA"

printf '\nOutdated packages in the incoming plan (cached metadata):\n'
while IFS= read -r package; do
  if [[ -n "$package" ]]; then brew outdated --formula "$package" || true; fi
done < <(awk -F '"' '/^[[:space:]]*brew[[:space:]]+"/ {print $2}' "$BUNDLE_FILE")
while IFS= read -r package; do
  if [[ -n "$package" ]]; then brew outdated --cask --greedy "$package" || true; fi
done < <(awk -F '"' '/^[[:space:]]*cask[[:space:]]+"/ {print $2}' "$BUNDLE_FILE")

printf '\nReviewed upstream commit: %s\n' "$UPSTREAM_SHA"
if (( PREVIEW_ONLY == 1 )); then exit 0; fi
if (( APPROVED == 0 )); then
  printf 'Continue? [y/N] '
  [[ -r /dev/tty ]] || { echo "Run interactively, or preview in the agent and approve that exact commit." >&2; exit 1; }
  IFS= read -r answer </dev/tty || answer=""
  [[ "$answer" =~ ^[Yy]$ ]] || { echo "Update cancelled."; exit 0; }
fi

git -C "$DOTFILES_DIR" merge --ff-only "$UPSTREAM_SHA"
brew update
brew bundle upgrade --file "$BUNDLE_FILE"

echo "Update complete. Run scripts/verify.sh to review setup health."

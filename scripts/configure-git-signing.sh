#!/bin/bash
set -Eeuo pipefail
umask 077

# Read a public key from stdin so it need not appear in shell history or the repo.
if [[ -t 0 ]]; then
  printf 'Paste the SSH public key from Bitwarden (never a private key): ' >&2
fi
IFS= read -r public_key || { echo 'No public key provided.' >&2; exit 1; }
case "$public_key" in
  ssh-*' '*|ecdsa-*' '*|sk-*' '*) ;;
  *) echo 'Expected an OpenSSH public key, not a private key or a path.' >&2; exit 1 ;;
esac
tmp="$(mktemp "${TMPDIR:-/tmp}/dotfiles-public-key.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
printf '%s\n' "$public_key" > "$tmp"
ssh-keygen -lf "$tmp" >/dev/null 2>&1 || { echo 'Invalid SSH public key.' >&2; exit 1; }

program="$(git config --global --get gpg.ssh.program || true)"
case "$program" in
  *1Password*|*1password*|*op-ssh-sign*) git config --global --unset-all gpg.ssh.program ;;
  '') ;;
  *) echo 'A custom global SSH signing program is configured; review it before continuing.' >&2; exit 1 ;;
esac
git config --global gpg.format ssh
git config --global user.signingkey "$public_key"
git config --global commit.gpgsign true
echo 'Git SSH signing configured locally. Check for repository or system overrides and verify signing with Bitwarden.'

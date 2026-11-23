# Guided setup

This is the agent's runbook after `bootstrap.sh` clones the repository and opens the chosen AI client.

## 1. Inventory and plan

Run `scripts/inventory.sh`. Review the output with the user. Compare installed Homebrew formulae/casks and `/Applications` against `Brewfile` and `manual-apps.md`.

Ask the user what should be done about apps present in `/Applications` but absent from `Brewfile`. Do not add applications based solely on their presence. Follow [manual-apps.md](manual-apps.md): list apps not managed by Homebrew, check whether a cask exists, and give official vendor/App Store links for manual installs. Do not persist the full machine-specific inventory in this public repo. The chosen AI app is selected in bootstrap and installed in addition to all current casks.

Ask separately whether to install optional Android Studio or full Xcode. Default to skipping both. Neither belongs in the required manifest; Command Line Tools remain the only Xcode-related bootstrap requirement.

Do not use Mackup. The old Mackup restore did not work for the user and its config has been removed. For app preferences, check the app's own account sync/iCloud support and ask the user which settings they need to migrate. Do not bulk-copy preference folders or use `--force` restore operations.

Ask the user to describe non-default macOS preferences they want preserved, grouped under:

- Dock
- Trackpad and mouse
- Keyboard shortcuts (known: ⌘Space opens Raycast)
- Other macOS settings

Use the current OS inventory only as a prompt for discussion. Do not read or export broad preference domains. Save confirmed, non-secret notes only to `~/.config/dotfiles/macos-notes.md`, not to this repo. Do not change other preferences without a clear request. The user has explicitly requested ⌘Space remain free for Raycast; guide them to keep Spotlight's ⌘Space shortcut disabled in System Settings and verify the observed state.

LuLu is part of the required Homebrew baseline. Tell the user to open LuLu after installation and approve its Network Extension in System Settings. If Little Snitch is present, tell the user to remove it using the vendor's Finder instructions before enabling LuLu; never remove its system extension by deleting files from Terminal.

OneDrive and Google Drive are Homebrew-managed apps in the baseline. Install the apps only; have the user sign in and choose sync locations themselves. Do not open either app or start sync during setup without asking.

Show the user a plan before changing any state beyond the bootstrap's selected app and baseline installation. Note which steps require a browser, Bitwarden sign-in, admin privileges, or a restart.

## 2. Apply configuration

After the user approves the displayed plan and manifest, run `scripts/setup.sh --yes`. It is idempotent and installs the required Homebrew manifest and the AI app chosen during bootstrap. Without `--yes`, the script displays the manifest and prompts interactively.

Shell configuration is standalone Zsh and does not require Oh My Zsh. If an existing `~/.zshrc` is a regular file, setup saves a timestamped backup before linking the repo version. It never deletes the backup. If `.zshrc` belongs to another symlink manager, stop and ask how to proceed.

The Homebrew manifest includes Ruby. Setup installs the Kamal gem with Homebrew Ruby if it is missing. The managed Zsh configuration adds Homebrew Ruby and its gem executables to `PATH`, so `ruby`, `gem`, and `kamal` are available in new interactive shells.

## 3. Bitwarden and GitHub SSH

Ask the user to:

1. Open Bitwarden and sign in. Unlock it when the Mac restarts as needed.
2. In Bitwarden desktop settings, enable the SSH agent as described in [Bitwarden’s SSH agent guide](https://bitwarden.com/help/ssh-agent/). Use SSH keys stored in the Bitwarden vault; no local SSH private key is required. The existing SSH key may still be in 1Password; let the user migrate it securely using the apps, without exposing private key material to the agent or chat. Register the **public** key with GitHub for authentication and signing.
3. Setup adds an include for `ssh-agent.conf` at the end of `~/.ssh/config`, so OpenSSH uses the Bitwarden desktop socket (`~/.bitwarden-ssh-agent.sock`) by default and existing SSH settings retain precedence. For a symlinked SSH config, add the include under `Host *` in the config you manage. The Zsh configuration also exports `SSH_AUTH_SOCK` for tools such as `ssh-add` and Git signing. For the Mac App Store version, follow the Bitwarden guide and set its socket locally before the include and in your shell environment. Keep key selection local to the machine; do not create or copy a private key into `~/.ssh`.
4. Configure Git's local identity on this Mac. Ask the user which **public** key in Bitwarden should sign commits, then have them provide it locally to `scripts/configure-git-signing.sh` when prompted. Do not ask for key material in chat or request a private key. The script configures global SSH signing and removes a 1Password signing-program override; it stops for other custom signing programs. Check for system or repository overrides. Use the local GitHub email if the user prefers to keep their email private.
5. Create `~/.config/dotfiles/allowed_signers` with one line in Git's allowed-signers format: `<GitHub email> namespaces="git" <SSH public key>`. Keep this file local, then run `git config --global gpg.ssh.allowedSignersFile ~/.config/dotfiles/allowed_signers` so Git can verify SSH signatures locally.
6. In GitHub settings, verify the SSH key is available and that signed commits appear as verified.

The user can run `gh auth login` for HTTPS/API workflows; it is separate from SSH Git transport. Never ask them to paste credentials.

## 4. Verify and finish

Run `scripts/verify.sh`. It checks the selected AI app, Homebrew manifests, shell link, Bitwarden app presence, the active SSH agent, GitHub SSH authentication, and Git signing configuration. Some checks require the user to unlock Bitwarden first. For an SSH-authenticated GitHub check, the agent should interpret GitHub's normal success message even if `ssh -T` returns a nonzero exit code.

Summarize completed items, manual app downloads, any blocked steps, and the commands `scripts/verify.sh` and `scripts/update.sh` for later use. Restart only if macOS or an app specifically requires it.

## Later maintenance

- Verify: `~/.dotfiles/scripts/verify.sh`
- Update: preview with `~/.dotfiles/scripts/update.sh --preview`; after user approval, apply only the exact reviewed commit with `~/.dotfiles/scripts/update.sh --yes --expected-upstream <SHA>`.
- Add/remove packages by editing `Brewfile` and reviewing the diff before applying.
- Re-run setup safely: `~/.dotfiles/scripts/setup.sh`

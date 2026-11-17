# Instructions for setup agents

This repository configures a personal Mac. Help the user restore a working environment with minimal terminal work, while preserving machine security and existing preferences.

## Start here

1. Read `SETUP.md`, `Brewfile`, `manual-apps.md`, and `macos-preferences.md`.
2. Run `scripts/inventory.sh` and explain the differences between the current Mac and this repo's manifests. Do not paste account names, email addresses, hostnames, tokens, or key material into chat or repository files.
3. Ask the user to review the inventory and name any additional apps or macOS settings that should be preserved. Ask specifically about Dock, trackpad, keyboard shortcuts, and other non-default settings. The known shortcut is ⌘Space for Raycast. Do not infer the intended values of other settings.
4. Present a short plan with package installs, shell changes, manual downloads, and any unresolved steps. Wait for the user's approval before changing system state. Bootstrap installs only the selected AI app; the user must review and approve the Homebrew manifest before running setup.
5. Run the relevant setup script(s), resolve ordinary failures where safe, and explain any remaining manual steps. After obtaining approval in chat, use `scripts/setup.sh --yes` so it can run without a terminal prompt.
6. Run `scripts/verify.sh` and report each result with a next action. Do not claim success for a check that was skipped or blocked.

## Security and change rules

- Never generate, copy, print, or commit SSH private keys. The user's SSH key and agent live in 1Password.
- Do not ask the user to paste passwords, 1Password recovery codes, tokens, private keys, or secret URLs into chat.
- Keep Git name/email and per-machine configuration in local settings, never in tracked files.
- Do not run remote scripts with `curl | sh` except the bootstrap command the user explicitly started. Inspect scripts in this repo before running them.
- Do not modify macOS defaults, keyboard shortcuts, Dock, trackpad, login items, firewall, sleep/security settings, or privacy permissions without a clear user request. `macos-preferences.md` is a record/checklist, not an automation file.
- Never use destructive cleanup, remove apps, reset settings, or overwrite user files. Setup backs up an existing `.zshrc`; if another manager owns it, stop and explain.
- Do not clone personal projects automatically. Ask which repositories the user wants, then use their configured GitHub SSH access.
- Treat all directly installed Homebrew formulae and casks in `Brewfile` as required. Do not drop or reclassify them without asking. If an installed app is absent from the manifest, ask whether to add it, mark it manual, or leave it unmanaged.
- Keep terminal work to a minimum and explain any required Terminal command in one copyable block.

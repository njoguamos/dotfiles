# Agent-ready Mac setup

This repo is a small, repeatable starting point for a new Mac. A bootstrap script clones it, installs the selected AI app, then opens the repo so that Codex, Claude, or OpenCode can inspect the setup and guide the rest.

The setup is intentionally reviewable: package lists are explicit, scripts are safe to rerun, existing shell files are backed up before linking, and macOS preferences are never changed by the installer.

## New Mac

1. Finish macOS Setup Assistant and connect to a trusted network.
2. Open Terminal and run:

   ```sh
   curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/njoguamos/dotfiles/main/bootstrap.sh | /bin/bash
   ```

3. Choose Codex (the default), Claude, or OpenCode. The script installs only the chosen AI app, then asks whether to open the repo in that app.
4. In the agent, follow [AGENTS.md](AGENTS.md) and [SETUP.md](SETUP.md). The agent will inventory the Mac, review the manifests and scripts with you, show a plan, then run the setup steps you approve.
5. Sign into 1Password when prompted and enable its SSH Agent. Add the 1Password public key to GitHub, configure Git signing, and complete the verification workflow.

If Command Line Tools are missing, macOS opens its installer. Finish that installation, then rerun the bootstrap command.

## Keep the repo private of personal data

Do not commit passwords, recovery codes, SSH private keys, account email addresses, machine names, app tokens, or private repository URLs. Put machine-specific notes in `~/.config/dotfiles/`, which is outside this repository. Configure Git identity on the machine itself. SSH private keys should stay in 1Password.

## Workflows

- `scripts/inventory.sh` — read-only OS, Homebrew, app, shell, 1Password, SSH, and Git configuration inventory. It avoids printing account identifiers or secret values.
- `scripts/setup.sh` — install the reviewed baseline and selected AI app; back up and link shell configuration; guide 1Password and Git setup.
- `scripts/verify.sh` — report each setup requirement as pass, needs attention, or optional.
- `scripts/update.sh` — preview incoming repo/package updates, then update this checkout and its Homebrew manifest; it does not update macOS or edit macOS preferences.

See [manual-apps.md](manual-apps.md) for software that may need a vendor download and [macos-preferences.md](macos-preferences.md) for settings that must be discussed before being changed.

App settings are migrated one app at a time using that app's supported sync/export. Mackup is not part of this setup.

# Apps outside the Homebrew baseline

This file describes how the setup agent should handle apps that are already in `/Applications` but are not installed from the repo's Homebrew manifest. It is a workflow guide, not a dump of this Mac's full application inventory.

## Inventory and recommendations

1. Scan `/Applications` recursively because some vendor apps, including Adobe apps, are nested in vendor folders.
2. Ignore helper apps and components that are not user-launchable. Compare each remaining `.app` with the installed Homebrew cask artifacts and `Brewfile`. A matching app name alone does not prove that Homebrew manages it.
3. In the setup conversation, list apps that are present but not Homebrew-managed. For each, say whether a Homebrew cask exists. Ask whether to add that cask, keep the app vendor-managed, or leave the app off the new Mac. Remove explicitly declined apps from the portable candidates and do not ask about them again during that setup.
4. For apps that need a manual install, provide the official vendor or Mac App Store source and any user action required, such as signing in, a license, admin approval, or a system extension approval.
5. Do not automatically install every app found on the current Mac. Do not copy the full machine-specific app inventory into this public repository. Ask before adding apps to the baseline.

Do not put a machine's discovered app names in this file. Keep the inventory report in the setup conversation unless the user explicitly asks to curate a portable app list in the public repo.

Microsoft Office is available as a Homebrew cask, but that cask conflicts with the `onedrive` cask. If the user wants both OneDrive sync and Office apps, recommend installing Office from the user's Microsoft 365 account rather than adding the conflicting cask.

The `google-drive` cask is for Google Drive file sync. Do not add Google Docs, Sheets, or Slides apps to the baseline; the user wants file sync only.

## Optional development apps

These are opt-in and are never part of the required `Brewfile`. Ask about each one individually and default to skipping it.

| App | Install route | Note |
| --- | --- | --- |
| Android Studio | Homebrew cask `android-studio` or [Android's official download](https://developer.android.com/studio) | Install only if the user wants Android development tools. |
| Full Xcode | [Mac App Store](https://apps.apple.com/us/app/xcode/id497799835?mt=12) | Optional. Command Line Tools are a separate bootstrap requirement; do not install full Xcode just to get Git/compiler tools. |

## Network firewall

LuLu is managed by the `lulu` cask in `Brewfile`. After Homebrew installs it, the user must open LuLu and approve the macOS network-filter extension in System Settings, then choose LuLu's initial rules. The installer does not grant those macOS permissions automatically.

Little Snitch is no longer part of this setup. If it is still installed, tell the user before activating LuLu. Follow [Objective Development's removal instructions](https://www.obdev.at/support/littlesnitch/u2j6s); do not delete its files from Terminal because macOS must remove the system extension correctly.

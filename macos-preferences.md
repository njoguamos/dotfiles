# macOS preferences to review

This file is a conversation checklist, not a source of defaults. Setup scripts do not write macOS preferences. Ask the user about each category, record only their confirmed intent in the local file `~/.config/dotfiles/macos-notes.md`, and ask again before any future script would change a preference.

## Known

- Keyboard shortcut: ⌘Space launches Raycast. Preserve this shortcut and do not re-enable the Spotlight shortcut over it.

## Ask the user

- Dock: which layout, size, auto-hide, recents, or other choices should be retained?
- Trackpad and mouse: which gestures, scrolling, tap-to-click, or other choices should be retained?
- Keyboard shortcuts: which other custom shortcuts or remappings should be retained?
- Other macOS preferences: which non-default settings matter to the user?

The inspected Mac currently reports Dock auto-hide on, position right, tile size 37, recent apps hidden, and trackpad tap-to-click enabled. The system's Spotlight shortcut entries 64 and 164 are disabled; the user says ⌘Space launches Raycast. Treat these only as observations from one machine; ask the user whether they are intentional before noting them as desired state. Do not export complete `defaults` domains: they can contain personal activity and account data.

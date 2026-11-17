# macOS preferences to review

This file is a conversation checklist, not a source of defaults. Setup scripts do not write macOS preferences. Ask the user about each category, record only their confirmed intent in the local file `~/.config/dotfiles/macos-notes.md`, and ask again before any future script would change a preference.

## Known

- Keyboard shortcut: free ⌘Space for Raycast by keeping Spotlight's ⌘Space shortcut disabled. The user has explicitly requested this target state.

## Ask the user

- Dock: which layout, size, auto-hide, recents, or other choices should be retained?
- Trackpad and mouse: which gestures, scrolling, tap-to-click, or other choices should be retained?
- Keyboard shortcuts: which other custom shortcuts or remappings should be retained?
- Other macOS preferences: which non-default settings matter to the user?

The inspected Mac currently reports Dock auto-hide on, position right, tile size 37, recent apps hidden, and trackpad tap-to-click enabled. The system's Spotlight ⌘Space shortcut entry 64 is disabled, matching the requested availability for Raycast. Treat other settings only as observations from one machine; ask before recording them as desired state. Do not export complete `defaults` domains: they can contain personal activity and account data.

During setup, guide the user to System Settings → Keyboard → Keyboard Shortcuts → Spotlight and ensure the ⌘Space Spotlight shortcut is off. Do not change unrelated shortcuts. The inventory/verification should report the Spotlight shortcut state so the user can confirm it remains available for Raycast.

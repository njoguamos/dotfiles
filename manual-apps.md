# Apps installed outside Homebrew

Some apps need a vendor installer, license, admin approval, or a manual security extension. Keep those separate from Homebrew so setup can report them without pretending to automate them.

| App | Setup | Verification | Current note |
| --- | --- | --- | --- |
| Little Snitch | Download from the vendor and approve its macOS network extension when prompted. Review the vendor's current install steps. | `test -d "/Applications/Little Snitch.app"` | Present on the Mac inspected 2026-11-17; user identified it as a manual install example. |

Before adding another app, ask whether the user wants it managed by Homebrew, installed manually, or left unmanaged. Never store license keys or download credentials here.

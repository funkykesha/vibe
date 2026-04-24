# Tech Context

## Build

```bash
cd work_guard_swift
./build.sh          # compile + assemble WorkGuard.app
open WorkGuard.app  # launch
./stop_workguard.sh # kill running instance
```

`build.sh` steps:
1. Stops existing instance
2. `swiftc Sources/*.swift -framework Cocoa -framework UserNotifications -o WorkGuard_bin`
3. `swiftc Sources/WorkGuardMenu/main.swift -framework Cocoa -o WorkGuardMenu_bin`
4. Assembles `WorkGuard.app/Contents/MacOS/` with both binaries
5. Copies `Resources/Info.plist` to `WorkGuard.app/Contents/`
6. Ad-hoc codesigns both binaries and app bundle (`codesign --sign -`)
7. Deletes intermediate `*_bin` files

No Xcode project, no SPM, no incremental compilation.

## File Locations

| Path | Purpose |
|---|---|
| `~/Library/Application Support/work_guard/config.json` | User config (persistent) |
| `~/.config/work_guard/work_guard.lock` | Single-instance flock + PID |
| `~/.config/work_guard/work_guard.log` | Debug log (NSLog output) |
| `~/.config/work_guard/status.json` | IPC: main → menu agent |
| `~/.config/work_guard/command.json` | IPC: menu agent → main |

## Permissions Required

| Permission | Purpose | Fallback behavior |
|---|---|---|
| Accessibility | CGEvent keyboard tap (`keyDown`) | Falls back to app-name detection only |
| Notifications | UNUserNotificationCenter alerts | Silently fails |

## Bundle Info

- Bundle ID: `com.workguard.app`
- Version: `2.0`
- Minimum macOS: `12`
- `LSUIElement = true` (no Dock icon)
- `NSUserNotificationAlertStyle = alert`

## Source Layout

```
Sources/
├── main.swift                    # Entry + AppDelegate + lock + launchMenuAgent
├── Config.swift                  # Codable config struct + load/save
├── ActivityMonitor.swift         # CGEvent tap + screen sleep + frontmost app
├── MonitoringLoop.swift          # 60s tick, overtime state machine, triggers
├── StatusBarController.swift     # StatusWriter: IPC bridge (writes status.json, reads command.json)
├── OverlayController.swift       # Full-screen NSPanel overlays
├── Notifier.swift                # UNUserNotificationCenter wrapper
├── AsciiArt.swift                # 15 art entries × 3 escalation levels
├── SettingsWindowController.swift # Programmatic dark settings window
└── WorkGuardMenu/
    └── main.swift                # Standalone menu bar agent binary
```

## Key Dependencies

- `Cocoa` — NSApplication, NSWindow, NSPanel, NSWorkspace, NSScreen
- `UserNotifications` — UNUserNotificationCenter
- `CoreGraphics` — CGEvent keyboard tap
- No third-party dependencies

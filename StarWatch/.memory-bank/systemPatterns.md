# System Patterns

## Architecture
Single binary, two modes via `main.swift`:
- `startwatch daemon` → `DaemonCommand.run()` → `NSApplication` (accessory, no dock icon)
- `startwatch <cmd>` → `CLIRouter.route()` → specific Command enum

## Module Boundaries
- **Core** — pure logic, no AppKit. Used by both CLI and daemon.
- **CLI** — enum-based commands with `static func run(args: [String])`. Exit codes meaningful.
- **Daemon** — AppKit only. `AppDelegate` coordinates all daemon components via closures.
- **Terminal** — `TerminalApp` protocol per terminal, `TerminalLauncher` as router.
- **IPC v1.0** — file-based: daemon writes `last_check.json`, CLI reads it. `trigger_check` flag file for daemon wakeup.

## Async Pattern
CLI commands use `runSync { await ... }` helper (semaphore-based bridge).  
Daemon uses `Task { ... await MainActor.run { } }` for UI updates.

## Config Flow
`ConfigManager.configURL` → `~/.config/startwatch/config.json`  
`StateManager.stateDir` → `~/.local/state/startwatch/`

## Testing
XCTest only. No mocks — real process/network calls with short timeouts.  
Test target: `StartWatchTests`. Run: `swift test`.

## Known Constraints
- `UNUserNotificationCenter` requires `.app` bundle — skip in CLI mode via `Bundle.main.bundleIdentifier != nil`
- `NSStatusItem` / `NSMenu` must be on main thread — AppDelegate and MenuBarController not marked `@MainActor` (implicit main thread via NSApplicationDelegate)

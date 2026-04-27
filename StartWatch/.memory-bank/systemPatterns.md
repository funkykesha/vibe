# System Patterns

## Architecture (v2.0)
Two-process design, single binary:
- `startwatch daemon` → headless, LaunchAgent, owns logic + IPC server + ProcessManager
- `startwatch menu-agent` → spawned via `open -na ~/Applications/StartWatchMenu.app --args menu-agent`, owns NSStatusItem + NSMenu

Daemon spawns menu-agent on start via `open -na` (not direct Process()) — only this registers as macOS UI agent.

## Module Boundaries
- **Core** — pure logic, no AppKit. Used by both CLI and daemon.
- **CLI** — enum-based commands with `static func run(args: [String])`. Exit codes meaningful.
- **Daemon** — AppKit only. `DaemonCoordinator` (in AppDelegate.swift) coordinates via closures.
- **MenuAgent** — `MenuAgentDelegate`, `MenuBarController`, `ConfigEditorWindow`. AppKit UI only.
- **Terminal** — `TerminalApp` protocol per terminal, `TerminalLauncher` as router.
- **IPC** — file-based polling `menu_command.json` every 2s. Commands: `trigger_check`, `start_service`, `stop_service`, `restart_service`. `name` field carries service name.

## ProcessManager
`Core/ProcessManager.swift` — daemon owns running child processes. `start()` launches detached process (stdout→/dev/null), `stop()` terminates, `restart()` = stop+start. Post-action: daemon calls `runCheck()` after 3s.

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
- `UNUserNotificationCenter` requires `.app` bundle — skip via `guard Bundle.main.bundleIdentifier != nil`
- `NSStatusItem` / `NSMenu` must be on main thread
- Swift tuple `(String, String)` doesn't bridge via ObjC `id` — `representedObject = ("start", name)` works at runtime but is unsafe; TODO: replace with struct
- `.app` bundle binary must be re-copied after each `/usr/local/bin` update (install.sh order dependency)

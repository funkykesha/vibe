# System Patterns

## Architecture (v2.0)
Two-process design, single binary:
- `startwatch daemon --no-menu` → headless owner when socket bind succeeds, LaunchAgent path
- app bundle/default or `menu-agent` → menu UI with `showMenu=true`; owner-with-menu if it binds socket, UI-only client if daemon already owns socket
- CLI commands route through `CLIRouter`; known commands must not fall into `NSApplication.run()`

Ownership is bind-first on `~/.local/state/startwatch/sock`: bind success means owner, `EADDRINUSE` plus reachable handshake means non-owner, stale socket recovery unlinks once and retries.

## Module Boundaries
- **Core** — pure logic, no AppKit. Used by both CLI and daemon.
- **CLI** — enum-based commands with `static func run(args: [String])`. Exit codes meaningful.
- **Daemon** — AppKit only. `DaemonCoordinator` (in AppDelegate.swift) coordinates via closures.
- **MenuAgent** — `MenuAgentDelegate`, `MenuBarController`, `ServiceMenuItemView`. AppKit UI only.
- **Terminal** — `TerminalApp` protocol per terminal, `TerminalLauncher` as router.
- **IPC** — Unix socket framed JSON. Commands/events: `trigger_check`, `get_status`, `subscribe`, `start_service`, `stop_service`, `restart_service`, `quit`; `name` field carries service name where needed.
- **State** — in-memory snapshot is primary; `last_check.json` is checkpoint/fallback. Menu uses socket subscription, not file polling, for live updates.

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

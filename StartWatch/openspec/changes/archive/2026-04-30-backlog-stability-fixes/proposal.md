## Why

StartWatch has 7 known reliability bugs that make it frustrating to use daily: services hang on restart with no feedback, the menu bar icon shows wrong service counts, old processes aren't killed on restart, and the daemon freezes when the .app bundle is missing. These issues block adoption and trust in the tool.

## What Changes

- `restart all` now spawns services in background, polls for readiness, and renders a live in-place terminal table with per-service status (⏳ starting / ✅ running / ❌ failed)
- Add `startupTimeout` per-service config field (default 10s) for controlling how long to wait during startup poll
- Fix `IPCClient.getLastResults()` to use config as source of truth — missing cache entries show as `unknown` instead of being silently dropped
- `RestartCommand` kills old processes via `ProcessManager.restart()` before spawning new ones
- Add ANSI cursor movement to `ANSIColors` for in-place terminal rendering
- Menu bar gets 4 icons: ♻️ all running / ⏳ any starting / ⚠️ mixed / ❌ all failed
- Menu bar polling adapts: 0.5s when any service is starting, 3s otherwise
- Add `isStarting` field to `CodableCheckResult` — CLI writes it before spawn, daemon clears it after check
- Daemon skips menu agent spawn if `.app` doesn't exist; add `--no-menu` flag for headless mode
- Add `startwatch list` command — shows service names from config
- Add `startwatch stop` command — sends `.quit` IPC to shutdown daemon + menu agent
- Improve `startwatch help` with examples and clarifications

## Capabilities

### New Capabilities

- `restart-live-output`: Live in-place terminal table during `restart all` with spawn+poll lifecycle
- `startup-state-propagation`: `isStarting` state written by CLI to last_check.json, read by menu bar
- `adaptive-menu-polling`: Menu bar polling rate adapts to presence of starting services
- `menu-bar-four-states`: Four distinct menu bar icons based on aggregate service state
- `headless-daemon-mode`: Daemon runs without attempting to spawn menu agent when .app is absent

### Modified Capabilities

- `service-lifecycle-logging`: `CodableCheckResult` gains `isStarting` field — schema change
- `ipc-unix-socket`: `IPCClient.getLastResults()` behavior changes — config is now authoritative source for service list

## Impact

- `Sources/StartWatch/Core/CheckResult.swift` — add `isStarting` to `CodableCheckResult`
- `Sources/StartWatch/Core/StateManager.swift` — no change needed
- `Sources/StartWatch/Core/Config.swift` — add `startupTimeout: Int?` to `ServiceConfig`
- `Sources/StartWatch/CLI/Formatting/ANSIColors.swift` — add cursor movement codes
- `Sources/StartWatch/CLI/Commands/RestartCommand.swift` — full rewrite with live output
- `Sources/StartWatch/IPC/IPCClient.swift` — fix getLastResults() service list logic
- `Sources/StartWatch/MenuAgent/MenuAgentDelegate.swift` — adaptive polling
- `Sources/StartWatch/Daemon/MenuBarController.swift` — four-state icon logic
- `Sources/StartWatch/Daemon/AppDelegate.swift` — .app existence check + --no-menu flag
- `Sources/StartWatch/CLI/CLIRouter.swift` — add list, stop commands + improved help
- New files: `Sources/StartWatch/CLI/Commands/ListCommand.swift`, `StopCommand.swift`

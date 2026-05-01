## Context

StartWatch is a macOS menu bar + CLI daemon written in Swift. Key components:
- `RestartCommand` — currently calls `ServiceRunner.run()` which blocks indefinitely on long-running processes
- `ProcessManager` — already has `restart(stop+start)` but `RestartCommand` doesn't use it
- `IPCClient.getLastResults()` — uses cache as source of truth for service list, dropping services not in cache
- `StateManager` — persists `[CodableCheckResult]` to `last_check.json` via polling IPC
- `MenuAgentDelegate` — polls `last_check.json` every 3s, two-state icon only (green/red)
- `DaemonCoordinator.spawnMenuAgentIfNeeded()` — calls `open -na /Applications/StartWatchMenu.app` unconditionally

## Goals / Non-Goals

**Goals:**
- Fix all 7 backlog bugs without introducing new architecture
- Add live terminal output during `restart all` with in-place rendering
- Propagate `isStarting` state from CLI → file → menu bar
- Four-state menu bar icon based on aggregate service status
- Adaptive polling (0.5s during startup, 3s otherwise)
- Headless daemon mode when `.app` is absent

**Non-Goals:**
- Event-driven IPC (replacing polling) — future work
- Tab completion for CLI
- Notification permission fix (skipped — edge case)
- Icon disappearance fix as a standalone bug (covered by other fixes)

## Decisions

### D1: Live terminal rendering — append-only with in-place update for `starting` rows

Each service gets one row. When a service finalizes (running/failed), its row is written as a permanent append. While still starting, its row is redrawn in-place using ANSI cursor-up (`\u{001B}[\(n)A`) + carriage return + clear-line (`\u{001B}[2K`).

**Alternative considered**: Full screen redraw (clear all N rows, reprint). Rejected — cursor flicker, harder to implement correctly across terminal emulators.

**Implementation**: `ANSIColors` gets `cursorUp(n)`, `clearLine` codes. `RestartLiveRenderer` struct tracks row positions and knows which rows are still mutable.

### D2: Spawn + poll replaces `waitUntilExit`

`ServiceRunner.run()` is not used in `RestartCommand` anymore. Instead:
1. `ProcessManager.restart(service:)` handles kill + spawn (non-blocking after spawn)
2. Poll loop calls `ServiceChecker.check(service:)` every 500ms
3. Loop exits per-service when `isRunning == true` OR elapsed > `startupTimeout`

`ServiceRunner.exec()` (interactive foreground mode) is unchanged — used elsewhere.

### D3: `isStarting` written to `last_check.json` by CLI before spawn

Before spawning any process, `RestartCommand` writes all target services with `isStarting: true` to `StateManager.saveLastResults()`. Daemon's next periodic check overwrites these entries with real results.

**Alternative considered**: Separate `startup_state.json` file. Rejected — adds a second file for menu to read, more complexity for same result.

`CodableCheckResult` gains `isStarting: Bool` (default `false`) for backward compat with existing cache files.

### D4: Config is authoritative source for service list in `IPCClient`

`getLastResults()` is rewritten to: load config → for each service in config → find matching cache entry if exists → return `CheckResult` with `isRunning: false, detail: "unknown"` if no cache entry.

Old entries in cache for services no longer in config are silently ignored.

### D5: Four-state icon priority: ⏳ > ⚠️ > ❌ > ♻️

Priority order (highest wins):
1. Any `isStarting == true` → ⏳
2. Any `isRunning == false` AND any `isRunning == true` → ⚠️
3. All `isRunning == false` → ❌
4. All `isRunning == true` → ♻️

### D6: Adaptive polling via timer invalidate + reschedule

When `pollStatus()` detects any `isStarting` entry, it invalidates the 3s timer and schedules a 0.5s one-shot timer. When no more starting entries, reschedules back to 3s repeating.

**Alternative**: Single timer at 0.5s always. Rejected — wastes CPU/battery in steady state.

### D7: `--no-menu` flag and `.app` existence check

`DaemonCommand.run()` parses args for `--no-menu`. `spawnMenuAgentIfNeeded()` checks `FileManager.default.fileExists(atPath: appPath)` before calling `open`. Both independently prevent the hang.

## Risks / Trade-offs

- **In-place rendering breaks in non-TTY** → `ANSIColors.isEnabled` already checks `isatty(STDOUT_FILENO)` — fall back to append-only when not a TTY
- **Race: daemon overwrites `isStarting` before CLI poll finishes** → acceptable — daemon check interval is minutes, CLI poll completes in <30s
- **`ProcessManager` is not shared between CLI and daemon** → CLI RestartCommand uses its own local `ProcessManager` instance; daemon has its own. No shared state needed — CLI just kills+spawns, daemon tracks via its own instance
- **`startupTimeout` default 10s may be too short for Postgres cold start** → documented in config example; user can override per-service

## Migration Plan

- No schema migration needed for `last_check.json` — `isStarting` has default `false`, old files decode cleanly
- No install.sh changes needed
- Existing 19 tests must pass — new tests added for `RestartCommand` poll logic and `IPCClient` service list fix

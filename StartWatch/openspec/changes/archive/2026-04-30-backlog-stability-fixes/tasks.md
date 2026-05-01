## 1. Foundation — Data Model Changes

- [x] 1.1 Add `isStarting: Bool` to `CodableCheckResult` in `CheckResult.swift` with default `false`
- [x] 1.2 Add `startupTimeout: Int?` to `ServiceConfig` in `Config.swift` with no default (handled by caller)
- [x] 1.3 Verify backward compatibility: ensure decoding old cache files without `isStarting` defaults to `false`

## 2. Terminal Rendering Infrastructure

- [x] 2.1 Add ANSI cursor movement to `ANSIColors.swift`: `cursorUp(_ n: Int)` and `clearLine`
- [x] 2.2 Add `isTTY` check property to `ANSIColors.swift` (reuse existing `isEnabled` logic for detection)

## 3. Service Lifecycle Management

- [x] 3.1 Rewrite `RestartCommand.swift` to use `ProcessManager.restart(service:)` instead of `ServiceRunner.run()`
- [x] 3.2 Implement spawn+poll loop in `RestartCommand.swift`: background spawn, 500ms interval poll, `startupTimeout` expiration
- [x] 3.3 Implement `RestartLiveRenderer` struct for in-place table rendering: track row positions, finalize rows on resolution
- [x] 3.4 Add append-only fallback when not TTY: check `ANSIColors.isTTY`, disable cursor codes if false
- [x] 3.5 Add `startwatch list` command in new `ListCommand.swift` that prints service names from config
- [x] 3.6 Add `startwatch stop` command in new `StopCommand.swift` that sends `.quit` IPC message
- [x] 3.7 Update `CLIRouter.swift` to route `list` and `stop` commands, improve help text with examples

## 4. IPC and State Management

- [x] 4.1 Rewrite `IPCClient.getLastResults()` in `IPCClient.swift`: iterate config services, match cache entries, return `unknown` status if no cache
- [x] 4.2 Update `RestartCommand.swift` to write `isStarting: true` to `StateManager.saveLastResults()` before spawning processes
- [x] 4.3 Update `DaemonCoordinator.stop()` in `AppDelegate.swift` to clear `isStarting` when stopping services

## 5. Menu Bar Updates

- [x] 5.1 Implement four-state icon logic in `MenuBarController.swift`: ⏳ starting > ⚠️ mixed > ❌ failed > ♻️ all-ok
- [x] 5.2 Add adaptive polling in `MenuAgentDelegate.swift`: 0.5s timer when any `isStarting`, 3s otherwise
- [x] 5.3 Update `pollStatus()` to detect `isStarting` entries and reschedule timer accordingly
- [x] 5.4 Test menu icon changes by manually creating cache files with different `isStarting` states

## 6. Daemon Headless Mode

- [x] 6.1 Parse `--no-menu` flag in `DaemonCommand.run()` and pass to `DaemonCoordinator.start()`
- [x] 6.2 Add `.app` existence check in `AppDelegate.swift`'s `spawnMenuAgentIfNeeded()` before calling `open`
- [x] 6.3 Skip menu agent spawn if `.app` doesn't exist OR `--no-menu` flag is set, with debug log

## 7. Testing and Verification

- [x] 7.1 Run existing 19 tests: `swift test` — ensure all pass
- [ ] 7.2 Manual test: `startwatch restart all` with 2 services, verify live table renders and exits after resolution
- [ ] 7.3 Manual test: Edit config to add new service, run `startwatch status`, verify new service shows as `unknown`
- [x] 7.4 Manual test: Run `startwatch list`, verify service names print correctly
- [ ] 7.5 Manual test: Run `startwatch stop`, verify daemon and menu agent exit
- [ ] 7.6 Manual test: Run daemon with `--no-menu`, verify no menu agent spawn attempt logged
- [ ] 7.7 Manual test: Trigger service restart, watch menu bar icon sequence ⏳ → ♻️

## 8. Documentation

- [x] 8.1 Update `README.md` with examples of `restart all` live table output
- [x] 8.2 Document `startupTimeout` config field in README.md with default and recommended values
- [x] 8.3 Document `--no-menu` flag usage for headless daemon mode
- [x] 8.4 Update help text: clarify `restart all` behavior, add examples for `list` and `stop`

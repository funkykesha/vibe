## 1. Fix reloadConfig to trigger status refresh

- [x] 1.1 In `Sources/StartWatch/Daemon/AppDelegate.swift`, add `runCheck()` call at the end of `reloadConfig()` after successful config swap

## 2. Cleanup debug code

- [x] 2.1 In `Sources/StartWatch/CLI/Commands/DaemonCommand.swift`, remove `fputs("[Daemon] Starting...\n", stdout)`, `fflush(stdout)`, `fputs("[Daemon] RunLoop started\n", stdout)` — restore to minimal 3-line form
- [x] 2.2 In `Sources/StartWatch/Core/FileWatcher.swift`, remove `print("[FileWatcher] Started polling...")` from `start()` and `print("[FileWatcher] File modified, calling callback")` from `checkForChanges()`

## 3. Build & Verify

- [x] 3.1 Run `swift build` — no errors, no warnings
- [x] 3.2 Run `swift test` — 19/19 pass
- [ ] 3.3 Manual test: reset config to 4 services, start daemon, add 5th service via jq, wait 2s, verify `startwatch status` shows 5 services
- [ ] 3.4 Manual test: save invalid config (remove `check.value`), wait 2s, verify status still shows previous valid config

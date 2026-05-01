## 1. Setup file watcher

- [x] 1.1 Add FileWatcher struct to Core directory: reads config file path, watches for modifications using DispatchSourceFileSystemObject
- [x] 1.2 Implement FileWatcher.start(onChangeDebounced:) with 200ms debounce to prevent duplicate triggers
- [x] 1.3 Add FileWatcher property to DaemonCoordinator; initialize in start() after loadConfig()
- [x] 1.4 Create method: `watchConfigFile()` — starts FileWatcher, calls `reloadConfig()` on file change

## 2. Implement config reload with validation

- [x] 2.1 Add `reloadConfig()` method to DaemonCoordinator
  - Load config from disk via ConfigManager.load()
  - Validate via ConfigManager.validate()
  - If valid: atomic swap self.config = newConfig, log success
  - If invalid: log error details, keep previous config, do not apply changes

- [x] 2.2 Enhance ConfigManager.validate() to return detailed error messages (not just [String])
  - Example: "Service 'Eliza' has empty check value. Example: ..."
  - Include service name in error for clarity

- [x] 2.3 Update DaemonCoordinator.loadConfig() to call validate() and log results
  - Log: "Config loaded: X services configured" on success
  - Log validation errors and halt startup if config invalid

## 3. Add logging for reload events

- [x] 3.1 Log config reload events with details:
  - On success: "Config reloaded: N services (was M)"
  - On validation error: "Config validation failed: [detailed error]"
  - On file watch error: "Failed to watch config file: [error]"

- [x] 3.2 Ensure logs use consistent format (timestamps, severity levels)

## 4. Handle race conditions

- [x] 4.1 Ensure config property is thread-safe: use atomic access or queue for updates
- [x] 4.2 Ensure in-flight checks use stable config snapshot (no mid-check config swaps)
- [x] 4.3 Test: start a long check, modify config during check, verify check completes with old config

## 5. Build & Test

- [x] 5.1 Run `swift build` — verify no errors
- [x] 5.2 Run `swift test` — verify 19/19 tests pass
- [x] 5.3 Manual test: start daemon, edit config, verify reload within 1s
- [x] 5.4 Manual test: edit config to invalid (remove a service field), verify error logged and config rejected
- [x] 5.5 Manual test: edit config back to valid, verify it reloads and applies

## 6. Cleanup

- [x] 6.1 Remove any debug logging added during development
- [x] 6.2 Verify no compiler warnings

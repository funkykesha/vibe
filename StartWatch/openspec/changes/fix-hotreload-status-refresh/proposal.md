## Why

After config file changes, `reloadConfig()` updates `self.config` but never triggers a new service check. The status command reads stale cached results until the next scheduled check (up to `checkIntervalMinutes`, typically 1–180 minutes). Users editing the config expect to see updated service counts immediately.

## What Changes

- Call `runCheck()` after a successful `reloadConfig()` so the cache updates within seconds
- Remove debug `fputs` logging from `DaemonCommand` (added during development)
- Remove verbose startup `print` from `FileWatcher.start()` (keep error-only prints)

## Capabilities

### New Capabilities

- `hotreload-status-refresh`: After config file changes, daemon runs a fresh service check and updates the status cache within ~2 seconds

### Modified Capabilities

_(none — no spec-level behavior changes to existing capabilities)_

## Impact

- `Sources/StartWatch/Daemon/AppDelegate.swift` — `reloadConfig()` method
- `Sources/StartWatch/CLI/Commands/DaemonCommand.swift` — remove debug output
- `Sources/StartWatch/Core/FileWatcher.swift` — remove verbose startup print

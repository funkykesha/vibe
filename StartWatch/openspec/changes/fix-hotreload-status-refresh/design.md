## Context

`DaemonCoordinator.reloadConfig()` atomically swaps `self.config` on valid file changes. However, `StatusCommand` reads results from `StateManager` (a file cache written by `runCheck()`). Without triggering a new check, the cache stays stale until the scheduler fires — potentially 180 minutes.

`FileWatcher` was also rewritten during debugging from `DispatchSourceFileSystemObject` (didn't trigger on atomic writes) to mtime polling (Timer, every 0.5s). Debug logging was left in `DaemonCommand` and `FileWatcher`.

## Goals / Non-Goals

**Goals:**
- Status reflects config changes within ~2 seconds after file save
- Remove debug code left from development
- No new dependencies or behavior changes beyond the single `runCheck()` call

**Non-Goals:**
- Thread-safety hardening beyond what already exists
- Changing poll interval or debounce behavior
- Unit tests for FileWatcher (manual end-to-end verification is sufficient)

## Decisions

**Trigger `runCheck()` inside `reloadConfig()` on success.**
Alternative: trigger check from `watchConfigFile()` callback. Rejected — `reloadConfig()` already has the validation outcome; calling from callback would require threading the result back up.

**Remove all debug output; keep only error-level prints.**
`print("[FileWatcher] File modified, calling callback")` → remove (verbose).
`print("[FileWatcher] File not found:")` and error prints → keep (useful for operators).

## Risks / Trade-offs

- **Double check on startup**: `start()` calls `loadConfig()` then schedules a check 15s later. After a config change, `reloadConfig()` immediately triggers another check. Two checks may overlap briefly — not harmful, just redundant. → No mitigation needed.
- **Polling CPU**: Timer fires every 0.5s for mtime stat. Negligible on macOS; acceptable for a daemon that's already running service checks.

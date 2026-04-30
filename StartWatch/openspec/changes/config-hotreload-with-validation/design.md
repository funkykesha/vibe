## Context

Currently, DaemonCoordinator loads config once at startup via `loadConfig()` (line 52-54 of AppDelegate.swift). Edits to `~/.config/startwatch/config.json` require manual daemon restart. Validation happens only in `ConfigManager.validate()` but is not called at load time, so invalid configs silently fail to update services.

## Goals / Non-Goals

**Goals:**
- Monitor config file using FileWatcher (async file I/O); reload on change
- Validate config before applying; reject invalid config and keep previous version
- Log reload events, what changed, and validation errors
- Zero manual restarts for config changes

**Non-Goals:**
- Watch other config files (only main config.json)
- Validate and fix config automatically (user must fix)
- GUI config editor (use system editor + hotreload)

## Decisions

**Decision 1: Use FileWatcher (async, lightweight) instead of polling**
- **Rationale**: Native macOS file monitoring via FSEvents/DispatchSourceFileSystemObject; no polling overhead; integrates with Swift async/await
- **Alternative (rejected)**: Poll config mtime every N seconds — wastes CPU, slower reaction

**Decision 2: Validate on load; reject invalid config silently keeping previous**
- **Rationale**: Prevents silent failures; user sees logs; services stay running on bad edit
- **Alternative (rejected)**: Auto-fix obvious errors — unpredictable; user wouldn't know what changed

**Decision 3: Log reload events to stdout (visible in daemon logs)**
- **Rationale**: User can `log stream --predicate 'process == "startwatch"'` to see config events
- **Alternative (rejected)**: Write to file — redundant with system logging

## Risks / Trade-offs

**Risk: File watcher misses rapid consecutive writes**
- **Mitigation**: Debounce file changes (100-200ms) before triggering reload

**Risk: Concurrent check() and config reload race**
- **Mitigation**: Use atomic config swap (volatile property + lock) so checks see consistent snapshot

**Risk: User creates invalid config and doesn't notice**
- **Mitigation**: Log validation error clearly; suggest correct format

## Migration Plan

1. Add FileWatcher to DaemonCoordinator
2. Call `loadConfig()` on file change events
3. Call `ConfigManager.validate()` before applying; log errors
4. Atomic swap: `self.config = newConfig` only if valid
5. Test: edit config, verify reload without restart
6. Verify validation rejects bad config and keeps previous version

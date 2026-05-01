## Context

StartWatch daemon monitors services and sends macOS notifications via `UNUserNotificationCenter`. Current state:
- Notifications show only service names ("Not running: Redis"), no failure reason
- No recovery or config-error notifications
- `FileWatcher` uses 500ms timer polling — misses atomic saves from editors (VSCode, vim rename inode)
- `configQueue` declared as concurrent but never used — `config` written directly, potential race with IPC callbacks
- `fw.log` debug file written on every file-change event, never cleaned up

All logic lives in `DaemonCoordinator` (`AppDelegate.swift`). Notification sending is delegated to `NotificationManager.shared`.

## Goals / Non-Goals

**Goals:**
- Show failure reason in notifications (from `CheckResult.detail`)
- Notify on service recovery and config validation failure
- Respect existing `sound` and `enabled` flags; add `showFailureDetails` flag
- Suppress notifications on daemon startup (only on state changes)
- Suppress failure notifications during `isStarting` phase (anti-spam)
- Replace file polling with FSEvents directory watcher + 200ms debounce
- Fix `configQueue` reader-writer pattern

**Non-Goals:**
- Visual changes to menu bar icons (backlog)
- Per-service notification settings
- Notification history or persistent log UI

## Decisions

### D1: Watch config directory, not the config file

**Decision**: `FileWatcher` opens an `O_EVTONLY` fd on the parent directory (`~/.config/startwatch/`), watches for `.write` and `.rename` events via `DispatchSource.makeFileSystemObjectSource`, then checks mtime of the target file to filter irrelevant events.

**Why**: Many editors (VSCode, vim, Sublime) use atomic saves — write to temp file, rename into place. A file-level fd becomes stale after rename and receives no further events. A directory fd survives inode replacement.

**Alternatives considered**:
- *File-level FSEvents*: Fails on atomic saves (inode replaced, old fd deaf).
- *Continue polling*: Works, but wastes CPU on 500ms timer and misses sub-500ms double saves. Debounce becomes meaningless.
- *Watch `.write | .rename | .delete` on file + reopen fd on rename*: More reliable than file-only, but more complex than directory watching with no benefit.

### D2: Debounce 200ms via cancellable DispatchWorkItem

**Decision**: On each FSEvents callback, cancel the previous `DispatchWorkItem` and schedule a new one 200ms later on `.main`.

**Why**: Editors may emit multiple events for one logical save (write temp, rename, update metadata). 200ms collapses these into a single reload. With polling the "natural debounce" was 500ms but unpredictable. 200ms is a deliberate, testable boundary.

### D3: configQueue sync barrier for writes

**Decision**: Back `config` with a private `_config` and computed property using `configQueue.sync { _config }` for reads and `configQueue.sync(flags: .barrier) { _config = newValue }` for writes.

**Why**: IPC server callbacks may arrive on background threads (not main). Using sync-barrier ensures the write completes before the caller continues, so `runCheck()` called immediately after `config = newConfig` sees the new value. Async barrier would lose this guarantee.

**Alternatives considered**:
- *Delete configQueue, stay on main*: Most callers are main-thread, but IPC is not. Removing the queue trades simplicity for silent race risk.
- *OSAllocatedUnfairLock* (pattern already used in `ServiceChecker`): Valid, but the computed property pattern is cleaner for a struct value type.

### D4: Notification state tracking via previousResults dictionary

**Decision**: `DaemonCoordinator` keeps `private var previousResults: [String: Bool]?`. `nil` = first run (baseline only, no notifications). Populated after every `runCheck()` completion.

**Why**: Notifications should fire on transitions (up→down, down→up), not on absolute state. Without previous state there's no way to detect a transition.

**Edge cases handled**:
- First run: silent (baseline)
- New service added to config: `previous[name] ?? true` → treated as "was running" → if down, notifies
- `isStarting == true`: excluded from newlyFailed filter
- `onlyOnFailure` does not suppress recovered notifications

## Risks / Trade-offs

- **FSEvents directory watch fires for any file in dir** → Mitigation: mtime check on target file path before triggering reload. Non-config files cause a stat() but no reload.
- **`configQueue.sync` on main thread blocks main briefly** → Mitigation: config reads/writes are tiny struct copies, sub-microsecond. Not a real concern.
- **`previousResults` not persisted across restarts** → Accepted. On restart, first check is silent. This is the desired behavior.
- **Notification delivery requires app bundle identifier** → Already handled: `NotificationManager.init` guards on `Bundle.main.bundleIdentifier != nil`.

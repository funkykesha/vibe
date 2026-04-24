# System Patterns

## Two-Process Architecture

```
WorkGuard (main daemon)          WorkGuardMenu (menu agent)
─────────────────────────        ──────────────────────────
AppDelegate                      NSApplication (.accessory)
  │                                │
  ├─ ActivityMonitor               ├─ Polls status.json every 1s
  ├─ MonitoringLoop                │   (mtime-based, skips if unchanged)
  ├─ OverlayController             │
  ├─ Notifier                      └─ Writes command.json on click
  └─ StatusWriter
       │
       ├─ Writes status.json on state change
       └─ Polls command.json every 0.5s
```

**IPC files** in `~/.config/work_guard/`:
- `status.json` → `{ title, tooltip, paused, items: [{id, text, enabled}] }`
- `command.json` → `{ command: "settings"|"pause"|"resume"|"test_overlay"|"quit" }`

## Component Wiring (AppDelegate)

```
ActivityMonitor ──► MonitoringLoop
                         │
                    onStatusChanged (main thread)
                         │
              ┌──────────┴──────────┐
         StatusWriter          OverlayController
                                    │
                               Notifier
```

`MonitoringLoop` calls `onStatusChanged` closure on every 60s tick, dispatched to main thread via `DispatchQueue.main.async`.

## MonitoringLoop State Machine

```
tick():
  if isPaused()          → emit .paused(until:), return
  if isWorkTime()        → reset minutesOvertime=0, emit .workTime, return
  if !isWorkHappening()  → reset minutesOvertime=0, emit .idle, return
  else                   → minutesOvertime++, check triggers
                             → notify if minutesOvertime % notificationInterval == 0
                             → overlay if minutesOvertime % overlayDelay == 0
```

Art/notification level: `min(2, minutesOvertime / 20)` — caps at 2 after 40+ min overtime.

## Exponential Overlay Lock

```swift
lockSecs = min(30 * (1 << overlayShowCount), 300)
// overlayShowCount=0 → 30s
// overlayShowCount=1 → 60s
// overlayShowCount=2 → 120s
// overlayShowCount=3 → 240s
// overlayShowCount=4+ → 300s (cap)
```

Close button appears only after `lockSecs` expire. Every 5s during countdown: `NSApp.activate(ignoringOtherApps: true)`.

## Atomic Write Pattern

Used everywhere config or IPC files are written:
```swift
// 1. Encode to data
// 2. Write to file.tmp
// 3. rename(file.tmp, file)  ← atomic on same filesystem
```

Prevents torn reads when both processes access same file concurrently.

## Activity Detection Logic

```
isWorkHappening() = !isScreenAsleep
                    AND (isKeyboardActive(idleThreshold: 300s)
                         OR isWorkAppActive())

isWorkAppActive() = frontmostApp name contains any workApp substring
                    (case-insensitive, bidirectional)

isWorkTime() = currentWeekday in workDays
               AND currentTime in [workStart, workEnd)
               (weekday: Mon=1 … Sun=7, converting from Apple's Sun=1)
```

## Single-Instance Lock

```swift
acquireLock() → flock(fd, LOCK_EX | LOCK_NB)
// Failure → NSAlert "already running" → exit(0)
// Success → write PID to lock file
releaseLock() → flock(fd, LOCK_UN) + close(fd)
```

Lock file: `~/.config/work_guard/work_guard.lock`

## Key Architectural Constraints

- Main process: `.accessory` activation policy (no Dock icon, no menu bar from main process)
- Overlay windows: `.screenSaver` level + `.canJoinAllSpaces` + `.stationary`
- Config loaded fresh on every MonitoringLoop tick AND on every IPC command
- `WorkGuardMenu` is spawned from `Contents/MacOS/WorkGuardMenu` — same bundle

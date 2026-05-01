# Fix: UNUserNotificationCenter crash in test environment

## Context

`swift test` crashes with `NSInternalInconsistencyException: bundleProxyForCurrentProcess is nil`
in `testMultipleSends_noCrash`. Exit code: signal 6 (SIGABRT), whole test suite aborts.

Root cause: `guard Bundle.main.bundleIdentifier != nil` is insufficient.
In xctest runner, `bundleIdentifier` = `com.apple.dt.xctest.tool` (non-nil), so guard passes.
But `UNUserNotificationCenter.current()` requires a real .app bundle proxy.
Async callbacks from prior send-tests accumulate; when `testMultipleSends_noCrash` runs
20 more async calls, the deferred crashes fire and SIGABRT.

## Fix

Replace every `Bundle.main.bundleIdentifier != nil` guard in `NotificationManager.swift`
with `Bundle.main.bundleURL.pathExtension == "app"`.

### File: `Sources/StartWatch/Notifications/NotificationManager.swift`

Three locations:

1. **private init()** line ~90:
   ```swift
   // before
   guard Bundle.main.bundleIdentifier != nil else { return }
   // after
   guard Bundle.main.bundleURL.pathExtension == "app" else { return }
   ```

2. **internal init(...)** line ~105:
   ```swift
   // before
   guard Bundle.main.bundleIdentifier != nil else { return }
   // after
   guard Bundle.main.bundleURL.pathExtension == "app" else { return }
   ```

3. **send()** line ~192:
   ```swift
   // before
   guard Bundle.main.bundleIdentifier != nil else { return }
   // after
   guard Bundle.main.bundleURL.pathExtension == "app" else { return }
   ```

`requestAuthorization()` — already fixed (line 112 changed in current session).

## Verification

```bash
swift build          # must pass, 0 errors
swift test           # must pass, 0 crashes
```

Expected: all NotificationManagerTests pass (or gracefully skip notification delivery).
No signal 6. No NSInternalInconsistencyException.

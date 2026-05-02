## Why

`swift test` exits with signal 6 (SIGABRT) in `NotificationManagerTests.testMultipleSends_noCrash` because `Bundle.main.bundleIdentifier != nil` is an insufficient guard — xctest runner has a bundleIdentifier but no app bundle proxy, causing `UNUserNotificationCenter.current()` to throw `NSInternalInconsistencyException`.

## What Changes

- Replace `guard Bundle.main.bundleIdentifier != nil` with `guard Bundle.main.bundleURL.pathExtension == "app"` in three locations inside `NotificationManager.swift` (private `init`, internal `init`, `send()`)
- One location (`requestAuthorization`) already patched in current session

## Capabilities

### New Capabilities

_(none — this is a bug fix)_

### Modified Capabilities

_(none — no spec-level behavior changes; production app bundle path extension is always `"app"`)_

## Impact

- **File**: `Sources/StartWatch/Notifications/NotificationManager.swift` — 3 guard replacements
- **Tests**: `swift test` must pass with 0 crashes after fix
- No API or behavioral change for the running macOS app

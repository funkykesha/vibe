## Context

`NotificationManager.swift` guards calls to `UNUserNotificationCenter.current()` with `Bundle.main.bundleIdentifier != nil`. In an Xcode test runner (`xctest` binary), `bundleIdentifier` returns `"com.apple.dt.xctest.tool"` — non-nil — so the guard passes. But `UNUserNotificationCenter.current()` internally calls `bundleProxyForCurrentProcess` which is nil outside a real `.app` process, raising `NSInternalInconsistencyException` → SIGABRT.

Affected locations in `NotificationManager.swift`:
1. `private init()` — `setupCategories()` guard
2. `internal init(onOpenReport:onRestartFailed:skipSetup:)` — `setupCategories()` guard  
3. `send()` — guard before `UNUserNotificationCenter.current().add(...)`
4. `requestAuthorization()` — **already patched** to `bundleURL.pathExtension == "app"`

## Goals / Non-Goals

**Goals:**
- `swift test` completes without SIGABRT
- All `NotificationManagerTests` pass or skip gracefully in CLI test environment
- No behavior change for the live `.app` process

**Non-Goals:**
- Mocking `UNUserNotificationCenter` for richer test assertions
- Refactoring notification architecture

## Decisions

**Use `Bundle.main.bundleURL.pathExtension == "app"` as guard**

Alternatives considered:
- `bundleIdentifier != nil` — current approach, insufficient (xctest has a bundleIdentifier)
- `ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil` — fragile, env-specific, couples to Xcode internals
- `bundleURL.pathExtension == "app"` — stable, correct: real macOS `.app` bundles always have `.app` extension; xctest binary does not

## Risks / Trade-offs

- `bundleURL.pathExtension == "app"` returns false for CLI daemon too — acceptable, daemon doesn't use notifications directly (menu agent `.app` does)
- If Apple changes xctest bundle structure, guard may need revisiting — low probability

## Migration Plan

1. Replace 3 remaining guards in `NotificationManager.swift`
2. Run `swift test` — verify 0 crashes
3. Run app manually — verify notifications still fire from `.app` bundle

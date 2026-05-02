# notification-test-stability Specification

## Purpose
TBD - created by archiving change fix-notification-test-crash. Update Purpose after archive.
## Requirements
### Requirement: NotificationManager is safe outside app bundle
`NotificationManager` SHALL NOT call `UNUserNotificationCenter.current()` when not running inside a real macOS `.app` bundle, preventing `NSInternalInconsistencyException` crashes in CLI and test environments.

#### Scenario: Guard passes only for real app bundles
- **WHEN** `Bundle.main.bundleURL.pathExtension` is `"app"`
- **THEN** `UNUserNotificationCenter.current()` calls proceed normally

#### Scenario: Guard blocks non-app environments
- **WHEN** `Bundle.main.bundleURL.pathExtension` is NOT `"app"` (xctest runner, CLI binary)
- **THEN** all `UNUserNotificationCenter` calls are skipped and no exception is thrown

#### Scenario: Test suite runs without SIGABRT
- **WHEN** `swift test` is executed from the command line
- **THEN** all `NotificationManagerTests` complete without signal 6 crash


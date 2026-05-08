## MODIFIED Requirements

### Requirement: NotificationManager is safe outside app bundle
`NotificationManager` SHALL NOT call `UNUserNotificationCenter.current()` when not running inside a real macOS `.app` bundle, preventing `NSInternalInconsistencyException` crashes in CLI, daemon, and test environments.

#### Scenario: Guard passes only for real app bundles
- **WHEN** `Bundle.main.bundleURL.pathExtension` is `"app"`
- **THEN** `UNUserNotificationCenter.current()` calls proceed normally from the app/menu-agent process

#### Scenario: Guard blocks non-app environments
- **WHEN** `Bundle.main.bundleURL.pathExtension` is NOT `"app"` (xctest runner, CLI binary, daemon binary context)
- **THEN** all `UNUserNotificationCenter` calls are skipped and no exception is thrown

#### Scenario: Test suite runs without SIGABRT
- **WHEN** `swift test` is executed from the command line
- **THEN** all `NotificationManagerTests` complete without signal 6 crash

#### Scenario: Daemon processes service failure
- **WHEN** daemon detects failed or recovered services
- **THEN** daemon records state without calling `UNUserNotificationCenter.current()`
- **THEN** daemon does not crash due to bundle proxy errors

## ADDED Requirements

### Requirement: Menu-agent owns macOS notification delivery
The system SHALL deliver macOS user notifications only from the app/menu-agent process.

#### Scenario: Services fail while menu-agent is running
- **WHEN** daemon writes failed service state
- **THEN** menu-agent observes the state through existing state or IPC mechanisms
- **THEN** menu-agent sends the macOS notification from the app bundle process

#### Scenario: Services recover while menu-agent is running
- **WHEN** daemon writes recovered service state
- **THEN** menu-agent observes the state through existing state or IPC mechanisms
- **THEN** menu-agent sends the recovery notification from the app bundle process

#### Scenario: Menu-agent is not running
- **WHEN** daemon writes notification-worthy state and menu-agent is not running
- **THEN** daemon does not attempt direct macOS notification delivery
- **THEN** daemon continues monitoring without crash

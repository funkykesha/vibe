## ADDED Requirements

### Requirement: Daemon does not own terminal launch for service control
Daemon service-control path SHALL never call terminal UI APIs (`NSWorkspace`, `NSAppleScript`, or terminal launch helpers) for `startService` and `restartService`.

#### Scenario: Background service start
- **WHEN** daemon handles `startService` for a service with `background == true`
- **THEN** daemon starts service process and returns `ok` without any terminal launch call

#### Scenario: Interactive service start
- **WHEN** daemon handles `startService` for a service with `background` unset or `false`
- **THEN** daemon returns `executeInTerminal` and does not invoke terminal UI APIs

### Requirement: Background flag explicitly controls daemon process spawning
Service config SHALL support optional `background` boolean that controls daemon-side process spawn behavior for start/restart.

#### Scenario: background true uses daemon process manager
- **WHEN** service has `background: true`
- **THEN** daemon start/restart path executes process via `ProcessManager` and returns `ok`

#### Scenario: background false delegates terminal intent
- **WHEN** service has `background: false` or omits field
- **THEN** daemon start/restart path returns `executeInTerminal` response

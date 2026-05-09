## ADDED Requirements

### Requirement: Daemon SHALL own service lifecycle
Service lifecycle actions SHALL be requested by CLI/Menu over IPC and executed or resolved by daemon runtime.

#### Scenario: CLI start requests daemon action
- **WHEN** user runs `startwatch start redis`
- **THEN** CLI sends `startService(name: "redis")` to daemon
- **AND** CLI does not use `ProcessManager`

#### Scenario: Menu action requests daemon action
- **WHEN** user clicks Start, Stop, or Restart for a service
- **THEN** Menu sends the corresponding IPC request to daemon

### Requirement: Background services SHALL run in daemon
If `service.background == true`, daemon SHALL execute start and restart commands through daemon-owned process lifecycle.

#### Scenario: Background start
- **WHEN** daemon handles `startService` for a background service
- **THEN** daemon starts the process through `ProcessManager`
- **AND** returns `ok` or `error`

### Requirement: Interactive services SHALL be launched by clients
If `service.background != true`, daemon SHALL return `executeInTerminal` for start and restart requests, and Menu/CLI SHALL launch the configured terminal.

#### Scenario: Interactive start
- **WHEN** daemon handles `startService` for a non-background service
- **THEN** daemon returns `executeInTerminal(command, workingDirectory?, serviceName)`
- **AND** it does not open a terminal

#### Scenario: CLI terminal handoff
- **WHEN** CLI receives `executeInTerminal`
- **THEN** CLI opens the configured terminal using shared `TerminalLauncher`

### Requirement: Service config SHALL support explicit stop command
`ServiceConfig` SHALL include optional `stop: String?`. Missing `stop` SHALL be backward compatible with existing config files.

#### Scenario: Old config decodes
- **WHEN** config file has no `stop` field
- **THEN** service config decodes successfully with `stop == nil`

### Requirement: stopService SHALL be daemon-side only
Daemon SHALL resolve stop by explicit stop command, managed PID, discovered PID/port, or error. It SHALL never return `executeInTerminal` for stop.

#### Scenario: Explicit stop command wins
- **WHEN** service has `stop` command
- **THEN** daemon executes that command and returns `ok` or `error`

#### Scenario: PID fallback escalates
- **WHEN** daemon discovers a process to stop
- **THEN** daemon sends SIGTERM, waits 5 seconds, and sends SIGKILL if the process is still alive

#### Scenario: No stoppable target
- **WHEN** service has no `stop` command and no target PID can be found
- **THEN** daemon returns `error("no stoppable target")`

#### Scenario: Non-background service has no stoppable target
- **WHEN** a non-background service has no `stop` command and no discoverable PID
- **THEN** daemon returns `error("no stoppable target")`
- **AND** daemon does not return `executeInTerminal`

### Requirement: Lifecycle actions SHALL require daemon online
Service lifecycle actions SHALL fail instead of falling back to local client execution when daemon is offline.

#### Scenario: CLI lifecycle while daemon offline
- **WHEN** user runs `startwatch restart redis` and daemon is offline
- **THEN** CLI prints `Daemon offline. Run 'startwatch install'`
- **AND** exits non-zero

#### Scenario: Menu lifecycle while daemon offline
- **WHEN** Menu detects daemon offline
- **THEN** service lifecycle menu items are disabled
- **AND** Menu shows Start Daemon action

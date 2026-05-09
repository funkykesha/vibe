## MODIFIED Requirements

### Requirement: Render live terminal table during `restart all`
System SHALL render terminal progress for `restart all` and `restart failed` from daemon-mediated service lifecycle actions. CLI SHALL use `getStatus` to choose targets and `restartService` for each target; it SHALL NOT call `ProcessManager` directly. Batch restart SHALL NOT open terminals for interactive services; terminal handoff SHALL only be honored for explicit single-service `restart <name>`.

#### Scenario: Initial table render with selected services
- **WHEN** user runs `startwatch restart failed` and daemon status reports 3 failed services
- **THEN** system renders 3 rows for the selected restart targets

#### Scenario: Batch restart skips interactive service
- **WHEN** daemon returns `executeInTerminal` while CLI is processing `restart all` or `restart failed`
- **THEN** CLI does not open a terminal for that service
- **AND** terminal output marks the service skipped with a per-service warning

#### Scenario: Single-service restart returns terminal handoff
- **WHEN** user runs `startwatch restart <name>` and daemon returns `executeInTerminal`
- **THEN** CLI opens the configured terminal and records that restart handoff was issued

#### Scenario: Service restart fails
- **WHEN** daemon returns `error` for a selected service
- **THEN** terminal output marks that service as failed and exits non-zero if any service failed

### Requirement: Services are spawned in background without blocking
Background service restart SHALL be performed by daemon without blocking the CLI process on long-running service commands.

#### Scenario: Daemon starts background services
- **WHEN** CLI sends `restartService` for a background service
- **THEN** daemon starts it through `ProcessManager`
- **AND** CLI receives `ok`

#### Scenario: Start command is a long-running server
- **WHEN** background service start command runs indefinitely
- **THEN** daemon process launch returns without waiting for command completion

### Requirement: Poll readiness with configurable interval and timeout
Readiness polling for restart progress SHALL be based on daemon status/checkpoint updates after daemon-mediated restart actions.

#### Scenario: Service starts quickly
- **WHEN** service becomes healthy after daemon restart action
- **THEN** subsequent CLI or Menu refresh observes running state

#### Scenario: Service never becomes ready
- **WHEN** service never passes readiness within configured timeout
- **THEN** daemon status eventually reports failed or not-running state

### Requirement: Fallback to append-only when not a TTY
System SHALL detect non-TTY output and fall back to append-only rendering.

#### Scenario: Output piped to file
- **WHEN** user runs `startwatch restart failed > output.txt`
- **THEN** status lines append without cursor movement codes

#### Scenario: Daemon offline
- **WHEN** user runs `startwatch restart all` and daemon is offline
- **THEN** CLI prints daemon-offline error and does not run foreground checks for lifecycle decisions

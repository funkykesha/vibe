## MODIFIED Requirements

### Requirement: Daemon exits cleanly on shutdown signal
The daemon SHALL terminate completely with exit code 0 when shutdown is initiated, with all daemon-owned resources released and no daemon-owned timers left running.

#### Scenario: User clicks quit button
- **WHEN** user clicks quit button in UI
- **THEN** menu-agent sends quit command to daemon
- **THEN** IPC server receives quit command and calls shutdown()
- **THEN** all services are stopped gracefully
- **THEN** all daemon-owned timers and scheduled checks are cancelled
- **THEN** all pending daemon DispatchWorkItem operations are cancelled
- **THEN** daemon logs DAEMON_SHUTDOWN_COMPLETE
- **THEN** daemon calls exit(0) and terminates
- **THEN** menu-agent terminates after quit request is sent

#### Scenario: No orphan timers after shutdown
- **WHEN** shutdown() is called with active repeating timers
- **THEN** daemon timers are invalidated immediately
- **THEN** no daemon timer fires after shutdown completes

#### Scenario: No orphan dispatch queue operations after shutdown
- **WHEN** shutdown() is called with pending asyncAfter operations in queue
- **THEN** all pending DispatchWorkItem operations are cancelled
- **THEN** no asyncAfter callbacks execute after shutdown completes

#### Scenario: No launchd respawn on clean shutdown
- **WHEN** daemon exits with code 0 after shutdown()
- **THEN** launchd interprets exit as clean shutdown (not crash)
- **THEN** daemon does not respawn automatically

### Requirement: Daemon shutdown logs completion event
The daemon SHALL log DAEMON_SHUTDOWN_COMPLETE event with timestamp before process termination.

#### Scenario: Shutdown completion logged
- **WHEN** shutdown() completes resource cleanup
- **THEN** DAEMON_SHUTDOWN_COMPLETE log entry is written to events.json
- **THEN** log entry contains timestamp, level=info, component=DaemonCoordinator

### Requirement: Shutdown handles edge cases without hanging
The shutdown process SHALL complete within reasonable time (< 5s) even if components are slow to respond.

#### Scenario: IPC server stops without deadlock
- **WHEN** ipcServer.stop() is called during shutdown
- **THEN** method returns without blocking
- **THEN** no threads or queues are deadlocked

#### Scenario: Scheduler cleanup is immediate
- **WHEN** scheduler = nil is executed
- **THEN** scheduler instance deinitializes without blocking
- **THEN** any pending check operations are discarded

## ADDED Requirements

### Requirement: CLI stop terminates daemon and menu-agent
The `startwatch stop` command SHALL stop both runtime processes: the LaunchAgent-backed daemon and the app/menu-agent UI.

#### Scenario: User runs CLI stop while both processes run
- **WHEN** user runs `startwatch stop`
- **THEN** the command requests daemon shutdown
- **THEN** the command terminates the menu-agent process if it remains running
- **THEN** no `startwatch daemon` or `startwatch menu-agent` process remains

#### Scenario: User runs CLI stop while daemon is already stopped
- **WHEN** user runs `startwatch stop` and daemon is not running
- **THEN** the command still terminates any remaining menu-agent process
- **THEN** the command exits without hanging

#### Scenario: User runs CLI stop while menu-agent is already stopped
- **WHEN** user runs `startwatch stop` and menu-agent is not running
- **THEN** the command still requests daemon shutdown
- **THEN** the command exits without hanging

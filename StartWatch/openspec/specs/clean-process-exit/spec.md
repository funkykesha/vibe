## ADDED Requirements

### Requirement: Daemon exits cleanly on shutdown signal
The daemon SHALL terminate completely with exit code 0 when shutdown is initiated, with all resources released and no processes or timers left running.

#### Scenario: User clicks quit button
- **WHEN** user clicks quit button in UI
- **THEN** IPC server receives quit command and calls shutdown()
- **THEN** all services are stopped gracefully
- **THEN** all timers (menu agent spawn, scheduled checks) are cancelled
- **THEN** all pending dispatch queue operations are cancelled
- **THEN** daemon logs DAEMON_SHUTDOWN_COMPLETE
- **THEN** daemon calls exit(0) and terminates

#### Scenario: No orphan timers after shutdown
- **WHEN** shutdown() is called with active repeating timer (menu agent spawn every 30s)
- **THEN** timer is invalidated immediately
- **THEN** no timer fires after shutdown completes

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

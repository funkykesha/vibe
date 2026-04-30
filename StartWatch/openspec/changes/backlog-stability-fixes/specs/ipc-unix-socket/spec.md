## MODIFIED Requirements

### Requirement: Restart command kills old processes before spawning
`restart <name|all>` SHALL first stop existing processes via `ProcessManager` before spawning new ones.

#### Scenario: restart all kills all old processes
- **WHEN** user runs `startwatch restart all` with 3 failed services
- **THEN** system calls `ProcessManager.restart()` for each service (stop, then spawn)

#### Scenario: External process still running on restart
- **WHEN** Redis is running (external, not managed by StartWatch) and user restarts it
- **THEN** system uses `ProcessManager.stop(service:)` which calls `pkill -f redis-server` to kill external process

## ADDED Requirements

### Requirement: List command shows service names
`startwatch list` SHALL display all service names from current config.

#### Scenario: List all services
- **WHEN** user runs `startwatch list`
- **THEN** system prints each service name from config, one per line

### Requirement: Stop command quits entire StartWatch
`startwatch stop` SHALL send `.quit` IPC message to daemon, which triggers graceful shutdown (daemon + menu agent).

#### Scenario: Stop daemon from CLI
- **WHEN** user runs `startwatch stop`
- **THEN** system sends IPC `.quit` message, daemon receives and calls `shutdown()`, menu agent exits

### Requirement: Help includes examples and clarifications
`startwatch help` output SHALL include usage examples and clarify `restart all` behavior (restarts only failed services).

#### Scenario: Help shows examples
- **WHEN** user runs `startwatch help`
- **THEN** system prints USAGE section with example commands like `startwatch restart Eliza Proxy`

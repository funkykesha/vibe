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

### Requirement: Daemon exposes Unix domain socket
The daemon SHALL listen on a Unix domain socket at `~/.local/state/startwatch/daemon.sock`. It SHALL accept one JSON message per connection and respond with a JSON status reply.

#### Scenario: Socket created on daemon start
- **WHEN** `startwatch daemon` starts
- **THEN** socket file appears at `~/.local/state/startwatch/daemon.sock`

#### Scenario: Socket removed on daemon stop
- **WHEN** daemon exits cleanly
- **THEN** socket file is deleted

### Requirement: CLI and menu-agent send commands via socket
The IPC client SHALL connect to `daemon.sock`, write a JSON command, read the reply, and close. The file-polling mechanism (`trigger_check` flag file, `menu_command.json`) SHALL be removed.

#### Scenario: Trigger check via socket
- **WHEN** `IPCClient.send(.triggerCheck)` is called while daemon runs
- **THEN** client connects to socket, sends `{"action":"trigger_check"}`, receives `{"ok":true}` within 1s, and disconnects

#### Scenario: Start service via socket
- **WHEN** `IPCClient.send(.startService("postgres"))` is called
- **THEN** daemon receives command, starts the process, responds `{"ok":true}`

#### Scenario: Daemon not running
- **WHEN** `IPCClient.send(...)` is called and socket file does not exist
- **THEN** send returns without error and logs "daemon not running" to stderr

### Requirement: Backward compatibility for CLI trigger_check
The `startwatch check` and `startwatch restart` commands SHALL still work when daemon is not running (they run checks inline), with no dependency on IPC socket.

#### Scenario: CLI works standalone
- **WHEN** `startwatch status` is called with no daemon running
- **THEN** CLI reads last cached results from StateManager, no socket connection attempted

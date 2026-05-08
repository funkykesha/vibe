## Purpose
Define daemon/client IPC over Unix socket for commands, snapshots, and fallback behavior.

## Requirements

### Requirement: Restart command kills old processes before spawning
`restart <name|all>` SHALL first stop existing processes via `ProcessManager` before spawning new ones.

#### Scenario: restart all kills all old processes
- **WHEN** user runs `startwatch restart all` with 3 failed services
- **THEN** system calls `ProcessManager.restart()` for each service (stop, then spawn)

#### Scenario: External process still running on restart
- **WHEN** Redis is running (external, not managed by StartWatch) and user restarts it
- **THEN** system uses `ProcessManager.stop(service:)` which calls `pkill -f redis-server` to kill external process

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
The daemon SHALL listen on a Unix domain socket at `~/.local/state/startwatch/sock` for backward compatibility. It SHALL support persistent bidirectional connections, accept length-prefixed framed messages (`[4-byte big-endian length][JSON payload]`), and decode multiple frames per stream safely.
It SHALL serve IPC status responses from in-memory state as source of truth. Checkpoint file SHALL NOT be used as a live read source while daemon is running.

#### Scenario: Socket created on daemon start
- **WHEN** `startwatch daemon` starts
- **THEN** socket file appears at `~/.local/state/startwatch/sock`

#### Scenario: Socket removed on daemon stop
- **WHEN** daemon exits cleanly
- **THEN** socket file is deleted

#### Scenario: Stale socket from crashed daemon
- **WHEN** daemon starts and socket file already exists from a previous crash
- **THEN** daemon removes stale socket file and creates a new listener on the same path

#### Scenario: Multiple framed messages on one connection
- **WHEN** a client sends two valid framed IPC messages on the same open socket
- **THEN** daemon decodes both frames in order and processes both messages without requiring reconnect

#### Scenario: Status served from memory
- **WHEN** connected client requests status while daemon is running
- **THEN** daemon replies using current in-memory snapshot without reading checkpoint from disk

#### Scenario: Startup restored state available immediately
- **WHEN** daemon starts and loads valid checkpoint into memory
- **THEN** first IPC status response can return restored state before first check cycle completes

### Requirement: CLI and menu-agent send commands via socket
The IPC client SHALL connect to `daemon.sock` and exchange framed IPC messages over a bidirectional stream. Menu-agent SHALL keep a long-lived subscription connection for push updates, while CLI commands MAY use short-lived request/response connections. The file-polling transport (`trigger_check` flag file, `menu_command.json`) SHALL not be used for live command delivery.
If socket is unavailable, CLI `status` SHALL fall back to reading `last_check.json` directly and report staleness.

#### Scenario: Trigger check via framed socket message
- **WHEN** `IPCClient.send(.triggerCheck)` is called while daemon runs
- **THEN** client sends framed `triggerCheck`, receives framed `ok` reply, and request completes successfully

#### Scenario: Start service via socket
- **WHEN** `IPCClient.send(.startService("postgres"))` is called
- **THEN** daemon receives framed command, starts the process, and responds with framed success or error message

#### Scenario: Daemon not running
- **WHEN** `IPCClient.send(...)` is called and socket file does not exist
- **THEN** client reports daemon unavailable and returns without crashing

#### Scenario: CLI disconnects after response
- **WHEN** CLI sends `getStatus` and receives `statusSnapshot`
- **THEN** CLI closes connection and does not remain subscribed for push events

#### Scenario: Live runtime path uses socket
- **WHEN** daemon socket is available and `startwatch status` is invoked
- **THEN** CLI fetches state through socket path and does not read checkpoint file

#### Scenario: Offline fallback path reads checkpoint
- **WHEN** daemon socket is unavailable and `startwatch status` is invoked
- **THEN** CLI reads `last_check.json` and prints daemon-offline stale-state indicator

#### Scenario: Staleness display format
- **WHEN** CLI reads checkpoint in offline fallback mode
- **THEN** output includes header `⚠️ Daemon offline. Last state from <relative_time>:` where `<relative_time>` is human-readable duration since checkpoint timestamp

### Requirement: Backward compatibility for CLI trigger_check
The `startwatch check` and `startwatch restart` commands SHALL still work when daemon is not running (they run checks inline), with no dependency on IPC socket.

#### Scenario: CLI works standalone
- **WHEN** `startwatch status` is called with no daemon running
- **THEN** CLI reads last cached results from StateManager, no socket connection attempted

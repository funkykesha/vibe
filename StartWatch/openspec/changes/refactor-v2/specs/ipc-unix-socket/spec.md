## MODIFIED Requirements

### Requirement: Restart command kills old processes before spawning
`restart <name|all|failed>` SHALL request daemon-owned restart behavior over IPC. CLI SHALL not call `ProcessManager` directly.

#### Scenario: restart failed uses daemon status
- **WHEN** user runs `startwatch restart failed`
- **THEN** CLI sends `getStatus`, filters failed services, and sends `restartService` for each selected service

#### Scenario: External process still running on restart
- **WHEN** a service is running externally and user restarts it
- **THEN** daemon-owned restart behavior stops the old process using service stop rules before starting or returning terminal handoff

### Requirement: Stop command quits entire StartWatch
`startwatch stop` SHALL no longer quit StartWatch. `startwatch stop <name>` SHALL send `stopService(name)` to daemon. Daemon lifecycle shutdown SHALL use `startwatch quit`.

#### Scenario: Stop service from CLI
- **WHEN** user runs `startwatch stop redis`
- **THEN** CLI sends `stopService(name: "redis")`
- **AND** daemon performs service stop behavior

#### Scenario: Stop without service name
- **WHEN** user runs `startwatch stop`
- **THEN** CLI returns an error with hint `Did you mean 'startwatch quit'?`

### Requirement: Daemon exposes Unix domain socket
The daemon SHALL listen on a Unix domain socket at `~/.local/state/startwatch/sock`. For PR1-6, it SHALL accept short-lived raw JSON request/response connections terminated by EOF. It SHALL serve status responses from in-memory state as source of truth. Checkpoint file SHALL NOT be used as a live read source while daemon is running.

#### Scenario: Socket created on daemon start
- **WHEN** `startwatch daemon` starts
- **THEN** socket file appears at `~/.local/state/startwatch/sock`

#### Scenario: Socket removed on daemon stop
- **WHEN** daemon exits cleanly
- **THEN** socket file is deleted

#### Scenario: Stale socket from crashed daemon
- **WHEN** daemon starts and socket file already exists from a previous crash
- **THEN** daemon removes stale socket file and creates a new listener on the same path

#### Scenario: Raw JSON request
- **WHEN** a client sends one raw JSON request and shuts down its write side
- **THEN** daemon reads request to EOF, decodes it, and sends one raw JSON response

#### Scenario: Status served from memory
- **WHEN** connected client requests status while daemon is running
- **THEN** daemon replies using current in-memory snapshot without reading checkpoint from disk

### Requirement: CLI and menu-agent send commands via socket
The IPC client SHALL connect to daemon socket and exchange short-lived raw JSON request/response messages. Menu-agent SHALL NOT keep a long-lived subscription connection in PR1-6. File command transports (`trigger_check` flag file, `menu_command.json`) SHALL not be used for live command delivery.

#### Scenario: Trigger check via raw socket message
- **WHEN** `IPCClient` sends `triggerCheck` while daemon runs
- **THEN** client sends raw JSON, receives `ok`, and request completes successfully

#### Scenario: Start service via socket
- **WHEN** `IPCClient` sends `startService(name: "postgres")`
- **THEN** daemon receives command and responds with `ok`, `executeInTerminal`, or `error`

#### Scenario: Daemon not running
- **WHEN** a lifecycle IPC request is attempted and socket is unavailable
- **THEN** client reports daemon unavailable and does not perform local lifecycle fallback

#### Scenario: Offline fallback path reads checkpoint
- **WHEN** daemon socket is unavailable and `startwatch status` is invoked
- **THEN** CLI reads `last_check.json` and prints daemon-offline stale-state indicator

### Requirement: Backward compatibility for CLI trigger_check
`startwatch check` SHALL still work when daemon is not running by running checks inline for output. Lifecycle commands SHALL NOT fall back to local execution when daemon is unavailable.

#### Scenario: CLI check works standalone
- **WHEN** `startwatch check` is called with no daemon running
- **THEN** CLI reads config, runs checks in the foreground, prints results, and exits

#### Scenario: CLI lifecycle does not work standalone
- **WHEN** `startwatch restart redis` is called with no daemon running
- **THEN** CLI reports daemon offline and exits non-zero

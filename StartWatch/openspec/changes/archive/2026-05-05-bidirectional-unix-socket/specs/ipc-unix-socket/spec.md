## MODIFIED Requirements

### Requirement: Daemon exposes Unix domain socket
The daemon SHALL listen on a Unix domain socket at `~/.local/state/startwatch/sock` for backward compatibility. It SHALL support persistent bidirectional connections, accept length-prefixed framed messages (`[4-byte big-endian length][JSON payload]`), and decode multiple frames per stream safely.

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

### Requirement: CLI and menu-agent send commands via socket
The IPC client SHALL connect to `daemon.sock` and exchange framed IPC messages over a bidirectional stream. Menu-agent SHALL keep a long-lived subscription connection for push updates, while CLI commands MAY use short-lived request/response connections. The file-polling transport (`trigger_check` flag file, `menu_command.json`) SHALL not be used for live command delivery.

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

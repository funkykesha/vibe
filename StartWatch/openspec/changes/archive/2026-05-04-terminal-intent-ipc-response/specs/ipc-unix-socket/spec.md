## MODIFIED Requirements

### Requirement: CLI and menu-agent send commands via socket
The IPC client SHALL connect to `daemon.sock`, write a JSON command, and close. For `startService` and `restartService`, the client SHALL read typed JSON response (`ok`, `executeInTerminal`, or `error`) before close. For non-service-control actions (`triggerCheck`, `stopService`, `restartAllFailed`, `quit`), existing one-way behavior SHALL remain supported.

#### Scenario: Trigger check via socket
- **WHEN** `IPCClient.send(.triggerCheck)` is called while daemon runs
- **THEN** client connects to socket, sends `{"action":"trigger_check"}`, and disconnects without requiring typed service response

#### Scenario: Start service returns typed response
- **WHEN** `IPCClient.sendAndReceive(.startService("postgres"))` is called
- **THEN** daemon returns one of `ok`, `executeInTerminal`, or `error` and client decodes it before disconnecting

#### Scenario: Restart service returns typed response
- **WHEN** `IPCClient.sendAndReceive(.restartService("postgres"))` is called
- **THEN** daemon returns one of `ok`, `executeInTerminal`, or `error` and client decodes it before disconnecting

#### Scenario: Daemon not running
- **WHEN** `IPCClient.sendAndReceive(...)` is called and socket file does not exist
- **THEN** client returns nil/error result without crashing and logs daemon-unavailable condition

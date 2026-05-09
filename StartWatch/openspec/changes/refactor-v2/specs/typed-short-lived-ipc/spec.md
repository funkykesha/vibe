## ADDED Requirements

### Requirement: IPC SHALL use one raw JSON request and one raw JSON response per connection
For PR1-6, clients SHALL open a Unix socket connection, write one Swift Codable enum JSON request, call `shutdown(SHUT_WR)`, read one Swift Codable enum JSON response, and close the connection.

#### Scenario: Client sends request to EOF
- **WHEN** a CLI or Menu client sends `startService(name)`
- **THEN** it writes one raw JSON payload to the socket
- **AND** it calls `shutdown(SHUT_WR)` to signal end of request

#### Scenario: Server replies once
- **WHEN** daemon reads a complete request to EOF
- **THEN** it decodes the request
- **AND** writes exactly one raw JSON response before closing or allowing the client to close

### Requirement: IPC SHALL expose typed request variants
The request protocol SHALL include `startService(name)`, `stopService(name)`, `restartService(name)`, `triggerCheck`, `getStatus`, and `quit`.

#### Scenario: Start request shape
- **WHEN** client sends start for Redis
- **THEN** request JSON is Codable enum form equivalent to `{"startService":{"name":"redis"}}`

#### Scenario: Status request shape
- **WHEN** client requests status
- **THEN** request JSON is Codable enum form equivalent to `{"getStatus":{}}`

### Requirement: IPC SHALL expose typed response variants
The response protocol SHALL include `ok`, `statusSnapshot(services)`, `executeInTerminal(command, workingDirectory?, serviceName)`, and `error(message)`.

#### Scenario: Terminal response shape
- **WHEN** daemon asks client to launch an interactive service
- **THEN** response JSON contains `executeInTerminal` with command, optional working directory, and service name

#### Scenario: Status response shape
- **WHEN** daemon handles `getStatus`
- **THEN** it returns `statusSnapshot` with current daemon service state

### Requirement: PR1-6 IPC SHALL not use framing or persistent subscriptions
Length-prefix framing and persistent subscribe/event-stream behavior SHALL not be active in PR1-6.

#### Scenario: Subscribe is not wired
- **WHEN** PR1-6 daemon starts IPC server
- **THEN** no active `subscribe` request handler is required for Menu state

#### Scenario: Length-prefix is not active
- **WHEN** client sends a PR1-6 request
- **THEN** it sends raw JSON without a 4-byte length prefix

### Requirement: IPC client SHALL apply connect and response timeouts
IPC client SHALL apply a 3-second connect timeout and a 5-second response timeout. On timeout it SHALL close the connection and report daemon-unresponsive state distinct from daemon-offline state.

#### Scenario: Connect timeout
- **WHEN** socket connect does not complete within 3 seconds
- **THEN** client closes the attempted connection
- **AND** reports daemon-offline

#### Scenario: Response timeout on live socket
- **WHEN** connect succeeds but no response is received within 5 seconds
- **THEN** client closes the connection
- **AND** reports daemon-unresponsive

#### Scenario: Successful response within timeout
- **WHEN** daemon responds within 5 seconds
- **THEN** client decodes and returns the response normally

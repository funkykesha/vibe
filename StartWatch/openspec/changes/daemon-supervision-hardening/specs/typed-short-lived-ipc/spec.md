## ADDED Requirements

### Requirement: IPC health check SHALL distinguish responsive, unresponsive, and offline daemon states
Daemon health checks SHALL classify daemon state using `getStatus` response behavior first and canonical LaunchAgent PID evidence second.

#### Scenario: Responsive daemon

- **WHEN** client sends `getStatus` and daemon returns a valid response within IPC timeout
- **THEN** client classifies daemon as responsive

#### Scenario: Connected daemon response timeout

- **WHEN** IPC connect succeeds but `getStatus` does not return within response timeout
- **THEN** client closes the IPC connection
- **AND** classifies daemon as unresponsive

#### Scenario: Connect fails but daemon PID is alive

- **WHEN** IPC connect fails and canonical LaunchAgent inspection finds a live daemon PID
- **THEN** client classifies daemon as unresponsive

#### Scenario: Connect fails and no daemon PID is alive

- **WHEN** IPC connect fails and canonical LaunchAgent inspection finds no live daemon PID
- **THEN** client classifies daemon as offline

#### Scenario: LaunchAgent inspection cannot parse PID

- **WHEN** IPC connect fails and `launchctl print gui/<uid>/com.user.startwatch` fails, times out, or cannot be parsed
- **THEN** client treats live PID as not found
- **AND** classifies daemon as offline

## ADDED Requirements

### Requirement: Clients can subscribe to daemon state stream
The daemon SHALL support persistent client subscriptions over IPC. A client that sends `subscribe` MUST be registered as an event subscriber and MUST receive a full `statusSnapshot` immediately after subscription is accepted.

#### Scenario: Initial snapshot after subscribe
- **WHEN** menu-agent connects and sends `subscribe`
- **THEN** daemon registers the connection as subscriber and sends `statusSnapshot` with current services state

#### Scenario: Multiple subscribers receive independent snapshots
- **WHEN** two clients subscribe concurrently
- **THEN** each client receives its own initial `statusSnapshot` without blocking the other client

### Requirement: Daemon pushes incremental state changes
When a service effective state changes, daemon SHALL broadcast `serviceChanged` events to all active subscribers without polling files. Effective state for broadcast comparison includes service operational state (`running`, `stopped`, `starting`, `error`) and error message text. It excludes check timestamp and response latency.

#### Scenario: Broadcast on state transition
- **WHEN** checker updates service state from `starting` to `running`
- **THEN** daemon broadcasts one `serviceChanged` event for that service to all subscribers

#### Scenario: No broadcast when state is unchanged
- **WHEN** checker computes a new status with the same effective state as previous
- **THEN** daemon does not emit a `serviceChanged` event

#### Scenario: Multiple services change in one check cycle
- **WHEN** checker detects state changes for multiple services in one cycle
- **THEN** daemon broadcasts separate `serviceChanged` events for each changed service, and order within the cycle is not guaranteed

### Requirement: Subscriber lifecycle is resilient
The daemon SHALL remove disconnected subscribers and continue broadcasting to remaining subscribers without memory leaks or server termination.

#### Scenario: Stale subscriber cleanup
- **WHEN** a subscriber socket closes unexpectedly
- **THEN** daemon removes that subscriber from registry before next broadcast cycle

#### Scenario: Broadcast continues after one subscriber fails
- **WHEN** sending to one subscriber returns write error
- **THEN** daemon drops failed subscriber and still sends event to all other subscribers

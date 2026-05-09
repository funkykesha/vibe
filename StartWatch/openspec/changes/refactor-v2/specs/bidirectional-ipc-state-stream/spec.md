## MODIFIED Requirements

### Requirement: Clients can subscribe to daemon state stream
Persistent daemon state stream subscription SHALL be deferred out of PR1-6. PR1-6 clients SHALL use short-lived request/response IPC and Menu SHALL use timer polling.

#### Scenario: PR1-6 menu starts without subscribe
- **WHEN** menu-agent starts in PR1-6
- **THEN** it does not open a persistent subscription connection
- **AND** it can render online/offline state using polling

#### Scenario: Stage III restores subscribe
- **WHEN** Stage III is implemented
- **THEN** client may send `subscribe` and receive `statusSnapshot`

### Requirement: Daemon pushes incremental state changes
Daemon push of `serviceChanged` events SHALL be a Stage III behavior, not an active PR1-6 requirement.

#### Scenario: PR1-6 state change
- **WHEN** daemon service state changes in PR1-6
- **THEN** Menu observes the change on a subsequent timer refresh

#### Scenario: Stage III state change
- **WHEN** Stage III persistent stream is implemented and service state changes
- **THEN** daemon broadcasts `serviceChanged` to subscribers

### Requirement: Subscriber lifecycle is resilient
Subscriber lifecycle management SHALL be implemented with Stage III persistent IPC and is not required for PR1-6 timer-polling Menu state.

#### Scenario: PR1-6 has no subscriber registry
- **WHEN** PR1-6 daemon starts
- **THEN** subscriber registry behavior is not required for Menu operation

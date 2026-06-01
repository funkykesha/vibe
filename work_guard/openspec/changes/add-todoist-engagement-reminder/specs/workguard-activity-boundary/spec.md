## MODIFIED Requirements

### Requirement: ActivitySignals remains future boundary
The system SHALL keep `ActivitySignals` as a coarse-grained activity boundary and MAY introduce at most one opt-in, default-disabled collector under it. Any collector SHALL be gated behind explicit user configuration and SHALL NOT capture raw activity history beyond what a coarse engagement timestamp requires.

#### Scenario: First collector is opt-in and default-disabled
- **WHEN** an `ActivitySignals` collector exists
- **THEN** it is disabled by default
- **THEN** it activates only after explicit user configuration
- **THEN** it produces coarse facts (engagement timestamps, counts), not raw event streams

#### Scenario: No implicit ingestion or export pipeline
- **WHEN** the collector is disabled
- **THEN** no activity ingestion occurs
- **THEN** no activity export pipeline runs

### Requirement: Future activity boundary remains local and coarse
`ActivitySignals` collectors SHALL operate on local, coarse-grained activity semantics. A collector MAY perform an outbound call only when that call is the user's explicitly configured request (for example, querying a user-provided third-party API token); all other activity facts remain local.

#### Scenario: Activity boundary stays coarse
- **WHEN** a collector reads local activity (frontmost app, browser history)
- **THEN** it derives only coarse facts and keeps them on the machine
- **THEN** it does not capture fine-grained keystrokes, full URLs history, or screen content

#### Scenario: Outbound only by explicit user configuration
- **WHEN** a collector makes an outbound request
- **THEN** the request is limited to the user-configured third-party endpoint and local environment token
- **THEN** no other activity data is transmitted off-machine

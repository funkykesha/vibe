## ADDED Requirements

### Requirement: Menu SHALL expose Force Stop only for daemon-unresponsive state
Menu Agent SHALL show `Force Stop Daemon` only when daemon health classification is unresponsive.

#### Scenario: Unresponsive daemon shows force stop

- **WHEN** menu polling classifies daemon as unresponsive
- **THEN** menu shows `Force Stop Daemon`

#### Scenario: Offline daemon hides force stop

- **WHEN** menu polling classifies daemon as offline
- **THEN** menu does not show `Force Stop Daemon`
- **AND** menu may show daemon start action instead

#### Scenario: Responsive daemon hides force stop

- **WHEN** menu polling classifies daemon as responsive
- **THEN** menu does not show `Force Stop Daemon`

### Requirement: Menu force-stop operation SHALL be latched while in progress
Once user starts menu force stop, Menu Agent SHALL keep a force-stop-in-progress state until the shared force-stop coordinator reports graceful completion, post-signal recovery, recovery failure, or unknown recovery.

#### Scenario: User starts force stop

- **WHEN** user clicks `Force Stop Daemon`
- **THEN** menu enters force-stop-in-progress state
- **AND** prevents duplicate force-stop actions while the operation is running

#### Scenario: Poll becomes responsive during force stop

- **WHEN** menu polling receives a responsive state while force stop is in progress
- **THEN** menu does not cancel the force-stop coordinator
- **AND** coordinator decides whether graceful quit completed or post-signal recovery verification is required

#### Scenario: Force stop recovers daemon

- **WHEN** force-stop coordinator reports recovered
- **THEN** menu exits force-stop-in-progress state
- **AND** hides `Force Stop Daemon`

#### Scenario: Force stop does not recover daemon

- **WHEN** force-stop coordinator reports no recovery or unknown recovery
- **THEN** menu exits force-stop-in-progress state
- **AND** shows actionable daemon troubleshooting state

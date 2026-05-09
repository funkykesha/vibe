## ADDED Requirements

### Requirement: System SHALL log daemon force-stop supervision events
Force-stop and force-enabled quit behavior SHALL emit structured daemon supervision events using the existing JSON log format.

#### Scenario: Graceful force quit completed

- **WHEN** force-enabled quit completes during the graceful wait without signal escalation
- **THEN** system logs `quit_completed_gracefully`
- **AND** log details include daemon PID when known

#### Scenario: Graceful force quit timed out

- **WHEN** force-enabled quit does not complete within 3 seconds and target PID remains alive
- **THEN** system logs `quit_timeout`
- **AND** log details include target PID and timeout seconds

#### Scenario: SIGTERM sent

- **WHEN** force stop sends `SIGTERM`
- **THEN** system logs `sigterm_sent`
- **AND** log details include target PID and signal delivery method

#### Scenario: SIGKILL sent

- **WHEN** force stop sends `SIGKILL`
- **THEN** system logs `sigkill_sent`
- **AND** log details include target PID and signal delivery method

#### Scenario: Force stop recovered

- **WHEN** force stop sent at least one signal and post-force-stop daemon answers `getStatus` before recovery deadline
- **THEN** system logs `force_stop_recovered`
- **AND** log details include recovered daemon PID when known

#### Scenario: Force stop did not recover

- **WHEN** force stop sent at least one signal and no daemon answers `getStatus` before recovery deadline
- **THEN** system logs `force_stop_no_recovery`
- **AND** log details include recovery deadline seconds

#### Scenario: Recovery wait interrupted

- **WHEN** CLI is interrupted during post-signal recovery verification
- **THEN** system logs `force_stop_recovery_interrupted`
- **AND** log details include recovery deadline seconds when known

#### Scenario: Graceful completion does not log recovery failure

- **WHEN** force-enabled quit completes without sending `SIGTERM` or `SIGKILL`
- **THEN** system logs `quit_completed_gracefully`
- **AND** system does not log `force_stop_no_recovery`

### Requirement: Force-stop logs SHALL distinguish skipped escalation from sent signals
The system SHALL NOT emit signal-sent events when graceful quit completes or when the target PID is no longer alive before the signal step.

#### Scenario: No SIGTERM log after graceful completion

- **WHEN** force-enabled quit completes during the graceful wait
- **THEN** system does not log `sigterm_sent`
- **AND** system does not log `sigkill_sent`

#### Scenario: No SIGKILL log after PID exits

- **WHEN** target PID exits after `SIGTERM` and before `SIGKILL`
- **THEN** system does not log `sigkill_sent`

#### Scenario: PID replaced before SIGKILL

- **WHEN** target PID exits after `SIGTERM` and a different daemon PID appears before `SIGKILL`
- **THEN** system logs `force_stop_pid_replaced`
- **AND** system does not log `sigkill_sent`

## ADDED Requirements

### Requirement: Force stop SHALL use graceful-first escalation
Force stop SHALL first attempt normal daemon quit over IPC, then escalate only if graceful quit does not complete within 3 seconds and the original target daemon PID remains alive.

See also: `Force-stop signals SHALL not redefine clean exit behavior` in `clean-process-exit`.

#### Scenario: Graceful quit completes during force request

- **WHEN** user runs `startwatch quit --force` and daemon exits during the 3-second graceful wait
- **THEN** system does not send `SIGTERM` or `SIGKILL`
- **AND** system verifies the original daemon PID is no longer alive via `kill(pid, 0)`
- **AND** system emits `quit_completed_gracefully`
- **AND** system skips recovery verification

#### Scenario: Graceful quit times out

- **WHEN** force stop sends quit IPC and the original daemon PID remains alive after 3 seconds
- **THEN** system emits `quit_timeout`
- **AND** system sends `SIGTERM` to the target daemon

#### Scenario: Original PID exits before SIGTERM

- **WHEN** force stop sends quit IPC and the original daemon PID is no longer alive after 3 seconds
- **THEN** system does not send `SIGTERM`
- **AND** system verifies the original daemon PID is no longer alive via `kill(pid, 0)`
- **AND** system emits `quit_completed_gracefully`
- **AND** system skips recovery verification

#### Scenario: Restart happens during graceful wait

- **WHEN** original daemon PID exits during the graceful wait and launchd starts a new daemon PID
- **THEN** force stop does not signal the new PID
- **AND** system may check whether the new daemon answers `getStatus` for reporting
- **AND** system does not emit `force_stop_recovered` unless a signal was sent

### Requirement: Force stop SHALL verify PID before each signal
Force stop SHALL capture the target daemon PID when available and re-check that same numeric PID with `kill(pid, 0)` immediately before sending each destructive signal.

#### Scenario: Same PID receives SIGTERM

- **WHEN** original target PID is still alive after graceful quit timeout
- **THEN** system sends `SIGTERM` to that PID through the configured signal path

#### Scenario: Same PID receives SIGKILL

- **WHEN** original target PID remains alive 5 seconds after `SIGTERM`
- **THEN** system sends `SIGKILL` to that same PID through the configured signal path

#### Scenario: Different PID appears before SIGKILL

- **WHEN** original target PID exits after `SIGTERM` and launchd starts a different daemon PID
- **THEN** system does not send `SIGKILL` to the different PID
- **AND** system proceeds to post-signal recovery verification

### Requirement: Force stop SHALL verify recovered daemon responsiveness
Force stop SHALL run recovery verification only if force stop sent at least one signal (`SIGTERM` or `SIGKILL`). If force-enabled quit completed gracefully without escalation, system SHALL emit `quit_completed_gracefully`, skip recovery verification, and complete successfully. When recovery verification runs, force stop SHALL report recovery only after a daemon answers `getStatus`; the recovery deadline SHALL be at least 13 seconds, covering LaunchAgent `ThrottleInterval=10` plus 3-second IPC connect timeout, but recovery MAY complete sooner when `getStatus` succeeds earlier.

#### Scenario: Recovered daemon answers getStatus

- **WHEN** post-force-stop daemon answers `getStatus` before the recovery deadline
- **THEN** system emits `force_stop_recovered`
- **AND** reports force stop recovered

#### Scenario: Graceful completion skips recovery

- **WHEN** force-enabled quit completes without sending `SIGTERM` or `SIGKILL`
- **THEN** system does not wait for recovered daemon responsiveness
- **AND** system does not emit `force_stop_recovered`
- **AND** system does not emit `force_stop_no_recovery`

#### Scenario: No recovered daemon answers getStatus

- **WHEN** no daemon answers `getStatus` before the recovery deadline
- **THEN** system emits `force_stop_no_recovery`
- **AND** reports recovery failed with instruction to run `startwatch doctor`

#### Scenario: CLI interrupted during recovery wait

- **WHEN** user interrupts CLI during post-signal recovery verification
- **THEN** CLI does not send rollback or extra signals
- **AND** system emits `force_stop_recovery_interrupted`
- **AND** recovery outcome is reported as unknown with instruction to run `startwatch doctor`

### Requirement: CLI force quit SHALL share force-stop behavior
`startwatch quit --force` SHALL use the same force-stop coordinator as menu `Force Stop Daemon`.

#### Scenario: Responsive daemon force quit

- **WHEN** user runs `startwatch quit --force` while daemon is responsive
- **THEN** CLI sends normal quit IPC first
- **AND** signal escalation occurs only if graceful quit fails to complete within 3 seconds

#### Scenario: Unresponsive daemon force quit

- **WHEN** user runs `startwatch quit --force` while daemon is unresponsive and a live PID exists
- **THEN** CLI performs force-stop escalation against the captured target PID

#### Scenario: Offline daemon force quit

- **WHEN** user runs `startwatch quit --force` and no daemon PID is live
- **THEN** CLI reports daemon offline
- **AND** CLI does not send `SIGTERM` or `SIGKILL`

### Requirement: Doctor SHALL report unresponsive daemon actionably
`startwatch doctor` SHALL perform a bounded daemon `getStatus` check and fail when daemon is unresponsive.

#### Scenario: Doctor finds unresponsive daemon

- **WHEN** daemon has PID `12345` but does not answer `getStatus` within timeout
- **THEN** doctor exits non-zero
- **AND** prints `daemon unresponsive (PID 12345). Run 'startwatch quit --force' to recover.`

#### Scenario: Doctor finds offline daemon

- **WHEN** daemon does not answer IPC and no live daemon PID is found
- **THEN** doctor reports daemon offline
- **AND** doctor does not recommend force stop

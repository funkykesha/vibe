## Purpose

Define status refresh and overtime accounting behavior so visible state updates quickly while time-based escalation remains accurate.

## Requirements

### Requirement: Fast visible status refresh

The system SHALL refresh user-visible status without waiting for the full overtime accounting interval. Settings saved while no deferral period is active SHALL apply to current enforcement within 10 seconds. Settings saved during an active deferral period SHALL update only `pending_period_settings` and MUST NOT change current enforcement until the next work-period boundary.

#### Scenario: Work state changes between minute boundaries

- **WHEN** the user enters or exits working state outside configured work time
- **THEN** the menu status and Swift status payload update within 10 seconds

#### Scenario: Configuration changes saved outside a deferral period

- **WHEN** settings are saved by the settings dialog and no deferral period is active
- **THEN** the running app applies the new configuration to current enforcement within 10 seconds

#### Scenario: Configuration changes saved during a deferral period

- **WHEN** settings are saved by the settings dialog while a deferral period is active
- **THEN** `pending_period_settings` is updated but current enforcement (overlay cadence, work-time check, ladder behaviour) continues to use `current_period_settings`

### Requirement: Elapsed-time overtime accounting

The system SHALL calculate overtime duration from elapsed time during an active after-hours work session rather than from monitoring loop iteration count.

#### Scenario: Fast polling does not accelerate overtime

- **WHEN** the monitor loop runs more often than once per minute
- **THEN** overtime minutes, notifications, and overlay trigger timing advance according to real elapsed time

#### Scenario: Overtime session resets

- **WHEN** the user returns to work time or stops working
- **THEN** the overtime session start time and escalation state are reset

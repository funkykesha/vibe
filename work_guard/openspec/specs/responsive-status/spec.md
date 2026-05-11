## Purpose

Define status refresh and overtime accounting behavior so visible state updates quickly while time-based escalation remains accurate.

## Requirements

### Requirement: Fast visible status refresh
The system SHALL refresh user-visible status without waiting for the full overtime accounting interval.

#### Scenario: Work state changes between minute boundaries
- **WHEN** the user enters or exits working state outside configured work time
- **THEN** the menu status and Swift status payload update within 10 seconds

#### Scenario: Configuration changes are saved
- **WHEN** settings are saved by the settings dialog
- **THEN** the running app applies the new configuration within 10 seconds

### Requirement: Elapsed-time overtime accounting
The system SHALL calculate overtime duration from elapsed time during an active after-hours work session rather than from monitoring loop iteration count.

#### Scenario: Fast polling does not accelerate overtime
- **WHEN** the monitor loop runs more often than once per minute
- **THEN** overtime minutes, notifications, and overlay trigger timing advance according to real elapsed time

#### Scenario: Overtime session resets
- **WHEN** the user returns to work time, stops working, or pauses monitoring
- **THEN** the overtime session start time and escalation state are reset

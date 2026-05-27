## Purpose

Define overlay lock duration escalation so lock timing intensifies predictably with a safe cap and deferral does not reset escalation state.

## Requirements

### Requirement: Overlay lock duration escalation

The system SHALL double overlay lock duration for each subsequent overlay in the same overtime session until the configured maximum is reached. Initial and maximum lock duration are module-level constants (`LOCK_INITIAL_SEC = 120` and `LOCK_MAX_SEC = 1800`).

#### Scenario: Overlay lock doubles

- **WHEN** overlays are shown repeatedly in one overtime session
- **THEN** lock durations progress as 120, 240, 480, 960, 1800 seconds until capped at 1800

#### Scenario: Overlay lock reaches maximum

- **WHEN** the next doubled lock duration would exceed `LOCK_MAX_SEC`
- **THEN** the app uses `LOCK_MAX_SEC` (1800 seconds)

#### Scenario: Overlay escalation resets

- **WHEN** the user returns to work time or stops working
- **THEN** the next overtime session starts again from `LOCK_INITIAL_SEC` (120 seconds)

### Requirement: Overlay deferral does not replace escalation

The system SHALL postpone only the currently scheduled next overlay when the user clicks a deferral step. Cadence doubling and lock-second escalation SHALL continue from where they were once the deferred overlay actually fires.

#### Scenario: Defer does not reset lock seconds

- **WHEN** the user has already seen two overlays in the current overtime session (lock at 480 sec) and then defers the next overlay by `+20`
- **THEN** when that next overlay eventually fires, its lock duration is 960 seconds (doubled from 480), not 120

#### Scenario: Defer does not reset cadence delay

- **WHEN** the user defers an overlay
- **THEN** the cadence doubling counter (which controls the delay between subsequent overlays) is unchanged; only the scheduled next-overlay time gains the step's minutes

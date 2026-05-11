## ADDED Requirements

### Requirement: Configurable overlay lock duration
The system SHALL allow users to configure initial and maximum overlay lock duration.

#### Scenario: Defaults are used
- **WHEN** no overlay lock settings exist in the config
- **THEN** the initial overlay lock duration is 30 seconds and the maximum overlay lock duration is 1800 seconds

#### Scenario: Settings are saved
- **WHEN** the user saves overlay lock duration settings in the settings dialog
- **THEN** subsequent overlays use the saved initial and maximum lock durations

### Requirement: Overlay lock duration escalation
The system SHALL double overlay lock duration for each subsequent overlay in the same overtime session until the configured maximum is reached.

#### Scenario: Overlay lock doubles
- **WHEN** overlays are shown repeatedly in one overtime session with an initial lock of 30 seconds and maximum of 1800 seconds
- **THEN** lock durations progress as 30, 60, 120, 240 seconds until capped

#### Scenario: Overlay lock reaches maximum
- **WHEN** the next doubled lock duration would exceed configured maximum
- **THEN** the app uses the configured maximum lock duration

#### Scenario: Overlay escalation resets
- **WHEN** the user returns to work time, stops working, or pauses monitoring
- **THEN** the next overtime session starts again from the configured initial lock duration

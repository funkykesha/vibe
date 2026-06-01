## Purpose

Define how WorkGuard decides the user is "working" from local input and app-presence signals, with no per-application allow-list and no user-controlled pause path.

## Requirements

### Requirement: Activity is any local input or app presence

The system SHALL treat the user as "working" when any of the following local signals are observed within the activity window: a keyboard event, a pointer (mouse / trackpad) event, an open lid, or a currently focused user-facing application. There SHALL NOT be a per-application allow-list filter.

#### Scenario: Keyboard event marks the user as working

- **WHEN** a key press is observed within the activity window
- **THEN** `is_work_happening()` returns `True`

#### Scenario: Mouse event marks the user as working

- **WHEN** a pointer move or click is observed within the activity window
- **THEN** `is_work_happening()` returns `True`

#### Scenario: Focused app alone marks the user as working

- **WHEN** the lid is open, a user-facing application is focused, and no keyboard or pointer events were observed within the activity window
- **THEN** `is_work_happening()` returns `True`

#### Scenario: All signals quiet means not working

- **WHEN** no keyboard, pointer, or focused-app activity is observed within the activity window and the lid is closed
- **THEN** `is_work_happening()` returns `False`

### Requirement: No user-controlled pause path

The system SHALL NOT expose a mechanism for the user to pause monitoring. The activity check MUST NOT be short-circuited by any persisted "paused" state, and no menu item, IPC command, or config field SHALL toggle such state.

#### Scenario: Legacy pause_until is ignored

- **WHEN** a legacy `config.json` contains a `pause_until` field
- **THEN** the loader drops it (per period-settings-freeze migration) and `is_work_happening()` evaluates activity signals normally without consulting any pause state

#### Scenario: No pause command from Swift menu

- **WHEN** the Swift menu agent writes any legacy `command.json` payload with `action = "pause"` or `action = "resume"`
- **THEN** the Python core ignores the action and does not change monitoring behaviour

### Requirement: Removal of work-apps whitelist

The system SHALL NOT read a `work_apps` list from configuration. The legacy `work_apps` field SHALL NOT influence activity detection.

#### Scenario: Legacy work_apps is dropped on migration

- **WHEN** a legacy `config.json` contains a `work_apps` list
- **THEN** the loader drops the field silently (per period-settings-freeze migration) and activity detection is based purely on input and focused-app signals

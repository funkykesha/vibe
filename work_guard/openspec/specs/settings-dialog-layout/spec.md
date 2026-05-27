## Purpose

Define settings dialog layout guarantees so controls remain visible, saved settings remain stable, and the dialog adapts correctly to whether a deferral period is active.

## Requirements

### Requirement: Settings dialog fits content

The settings dialog SHALL size itself so all controls and action buttons are fully visible on macOS in both Mode 1 (no active deferral period) and Mode 2 (active deferral period).

#### Scenario: Dialog opens with default settings (Mode 1)

- **WHEN** the user opens the settings dialog while no deferral period is active
- **THEN** the `[Дефолт] [Сохранить]` buttons are fully visible without clipping

#### Scenario: Dialog opens during an active deferral period (Mode 2)

- **WHEN** the user opens the settings dialog while a deferral period is active
- **THEN** the banner, both rows per field (`Следующий / Текущий` and `Было / —`), and the `[Дефолт] [Предыдущий] [Сохранить]` buttons are fully visible without clipping

### Requirement: Settings dialog preserves existing config fields

The settings dialog SHALL preserve config fields it does not edit directly, including `calendar_source`, `calendar_cache_days`, `pending_period_settings` (when not currently being saved), and `deferral`.

#### Scenario: Calendar fields exist

- **WHEN** the user saves settings while `calendar_source` and `calendar_cache_days` exist in the config
- **THEN** those fields are preserved unchanged in the persisted config

#### Scenario: Active deferral state exists

- **WHEN** the user saves settings while `deferral` is non-null
- **THEN** `deferral.period_id`, `deferral.steps_consumed`, and `deferral.next_overlay_at` are preserved unchanged in the persisted config

### Requirement: Schedule-only editable surface

The settings dialog SHALL expose exactly three editable fields: `work_start`, `work_end`, `work_days`. The dialog MUST NOT expose `overlay_delay_min`, `overlay_lock_initial_sec`, `overlay_lock_max_sec`, `notification_interval_min`, `work_apps`, `pause_until`, `calendar_source`, or `calendar_cache_days`.

#### Scenario: Dialog renders only schedule fields

- **WHEN** the user opens the settings dialog
- **THEN** the dialog shows input controls for `work_start`, `work_end`, and `work_days` only

### Requirement: Mode 1 layout — no active deferral period

When no deferral period is active at the moment the dialog opens, the dialog SHALL render a single editable row per field labeled `Текущий` and SHALL show only the `[Дефолт]` and `[Сохранить]` buttons.

#### Scenario: Save in Mode 1 writes current settings directly

- **WHEN** the user clicks `[Сохранить]` in Mode 1
- **THEN** the form values are written to `current_period_settings` and `pending_period_settings` is left as `null`

#### Scenario: Default button in Mode 1

- **WHEN** the user clicks `[Дефолт]` in Mode 1
- **THEN** the editable row is filled with `config.DEFAULTS` values for `work_start`, `work_end`, and `work_days`

### Requirement: Mode 2 layout — active deferral period

When a deferral period is active at the moment the dialog opens, the dialog SHALL render a banner stating that changes will apply in the next work period along with the computed next-period start datetime, and SHALL render two rows per field: an editable `Следующий / Текущий` row pre-filled from `pending_period_settings` (if non-null) otherwise `current_period_settings`, and a read-only `Было / —` row showing the snapshot of `current_period_settings` at dialog open. The dialog SHALL show the three buttons `[Дефолт]`, `[Предыдущий]`, `[Сохранить]`.

#### Scenario: Banner shows next-period start

- **WHEN** the dialog opens during an active deferral period
- **THEN** the banner shows `Изменения применятся в следующий рабочий период (начнётся: <weekday HH:MM>, <YYYY-MM-DD>)` where the datetime equals `next_work_start_after(now, current_period_settings)`

#### Scenario: Editable row pre-fill prefers pending

- **WHEN** the dialog opens with `pending_period_settings` non-null
- **THEN** the editable `Следующий / Текущий` row is populated with `pending_period_settings` values

#### Scenario: Editable row pre-fill falls back to current

- **WHEN** the dialog opens with `pending_period_settings = null` during an active deferral period
- **THEN** the editable `Следующий / Текущий` row is populated with `current_period_settings` values

#### Scenario: Read-only row collapses to dashes when unchanged

- **WHEN** the editable value of a field equals the dialog-open snapshot of `current_period_settings`
- **THEN** the `Было / —` row for that field renders the literal `—` (and for the `work_days` checkbox row each column renders as `—`)

#### Scenario: Save writes pending in Mode 2

- **WHEN** the user clicks `[Сохранить]` in Mode 2 and the form differs from `current_period_settings`
- **THEN** `pending_period_settings` is written as a full snapshot of the form values and `current_period_settings` is left unchanged

#### Scenario: Save clears pending when form equals current

- **WHEN** the user clicks `[Сохранить]` in Mode 2 and the form equals `current_period_settings` exactly
- **THEN** `pending_period_settings` is set to `null` and `current_period_settings` is left unchanged

#### Scenario: Previous button resets to dialog-open snapshot

- **WHEN** the user clicks `[Предыдущий]` in Mode 2
- **THEN** the editable row is filled with the dialog-open snapshot of `current_period_settings`

#### Scenario: Default button in Mode 2

- **WHEN** the user clicks `[Дефолт]` in Mode 2
- **THEN** the editable row is filled with `config.DEFAULTS` values

### Requirement: Schedule validation before save

The settings dialog SHALL prevent saving a schedule that cannot produce a future work-period boundary. Specifically, `work_days` MUST be non-empty and `work_start` MUST be strictly earlier than `work_end`.

#### Scenario: Empty work_days blocks save

- **WHEN** the user attempts to save with `work_days` empty
- **THEN** the `[Сохранить]` button is disabled and the form indicates that at least one weekday must be selected

#### Scenario: Reversed work hours block save

- **WHEN** the user attempts to save with `work_start >= work_end`
- **THEN** the `[Сохранить]` button is disabled and the form indicates that the start time must be before the end time

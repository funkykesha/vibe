## Purpose

Define how schedule settings are split into active (`current_period_settings`) and deferred (`pending_period_settings`) slots, how a deferral period is identified and bounded, when pending settings are promoted, and how legacy flat configs migrate into the new shape.

## Requirements

### Requirement: Current and pending period settings split

The system SHALL store schedule settings in two independent slots:
`current_period_settings` (the active rules) and `pending_period_settings`
(the rules that take effect on the next work-period start, or `null`).
Both slots SHALL hold the same set of fields: `work_start`, `work_end`,
`work_days`. All overtime enforcement (work-time check, overlay scheduling,
notification firing) SHALL read from `current_period_settings` only.

#### Scenario: Enforcement reads current snapshot

- **WHEN** `current_period_settings.work_end` is `19:00` and `pending_period_settings.work_end` is `18:00` and `now` is `18:30`
- **THEN** the app treats `now` as within work hours (no overtime accrues)

#### Scenario: Pending slot is full snapshot, not a diff

- **WHEN** the user saves the settings dialog during an active deferral period after editing only `work_end`
- **THEN** `pending_period_settings` is written as a complete `{work_start, work_end, work_days}` object whose fields equal the dialog form values, not a partial diff

### Requirement: Deferral period identity and boundary

The system SHALL identify the active deferral period by `deferral.period_id`, which equals the ISO datetime of the `work_end` (computed against `current_period_settings`) that opened the period. The period SHALL span from that `work_end` to the next `is_work_time()` False → True transition computed against `current_period_settings`.

#### Scenario: Period opens at first overtime onset

- **WHEN** `_overtime_started_at` becomes non-null for the first time after the day's `work_end`
- **THEN** `deferral.period_id` is set to the ISO datetime of that `work_end` (e.g. `2026-05-26T19:00:00`)

#### Scenario: Period boundary closes when work hours resume

- **WHEN** the per-tick check sees the previous tick as `is_work_time()=False` and the current tick as `is_work_time()=True` under `current_period_settings`
- **THEN** the app promotes `pending_period_settings` into `current_period_settings`, clears `pending_period_settings` to `null`, and clears `deferral` to `null` in a single config write

### Requirement: Pending settings promotion at boundary

The system SHALL apply `pending_period_settings` only at the work-period boundary transition. Pending settings MUST NOT influence enforcement before that boundary.

#### Scenario: Pending promotion atomicity

- **WHEN** the boundary transition fires and `pending_period_settings` is non-null
- **THEN** `current_period_settings` becomes a deep copy of `pending_period_settings` and `pending_period_settings` is set to `null` in the same write

#### Scenario: No pending settings at boundary

- **WHEN** the boundary transition fires and `pending_period_settings` is `null`
- **THEN** `current_period_settings` is left unchanged and `deferral` is cleared to `null`

### Requirement: Persistence across restart

The system SHALL persist `current_period_settings`, `pending_period_settings`, and `deferral` to `~/.config/work_guard/config.json` after every change and restore them on launch. A restart MUST NOT cause `pending_period_settings` to apply earlier than the next boundary.

#### Scenario: Restart inside the same period

- **WHEN** the app restarts and `deferral.period_id` is non-null and `now` is before `next_work_start_after(period_id, current_period_settings)`
- **THEN** the app preserves `current_period_settings`, `pending_period_settings`, and `deferral` unchanged

#### Scenario: Restart after the period boundary already passed

- **WHEN** the app restarts and `now` is at or after `next_work_start_after(period_id, current_period_settings)`
- **THEN** the app applies the same atomic promotion as the live boundary transition: `current` ← `pending` (if non-null), `pending` ← `null`, `deferral` ← `null`

### Requirement: Legacy config migration

The system SHALL detect a legacy flat `config.json` (no `current_period_settings` key) on load and rewrite it into the new shape, preserving `work_start`, `work_end`, `work_days` under `current_period_settings`, dropping `pause_until`, `work_apps`, `notification_interval_min`, `overlay_delay_min`, `overlay_lock_initial_sec`, `overlay_lock_max_sec`, and leaving `calendar_source` and `calendar_cache_days` at the top level.

#### Scenario: First launch after upgrade

- **WHEN** the app starts and `config.json` lacks the `current_period_settings` key
- **THEN** the app writes a backup at `~/.config/work_guard/config.json.pre-deferral.bak`, lifts schedule fields into `current_period_settings`, drops the deprecated fields silently, sets `pending_period_settings = null` and `deferral = null`, and persists the new shape immediately

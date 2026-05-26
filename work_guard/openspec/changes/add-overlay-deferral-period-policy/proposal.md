## Why

WorkGuard currently treats after-hours enforcement as an immediate function of
the latest settings, so the user can accidentally or deliberately reset the
next overlay by changing settings or restarting the app. The pause feature
lets the user disable monitoring outright, defeating the whole purpose of the
tool. The settings dialog also exposes many low-level knobs (lock duration,
overlay delay, notification interval, work-apps whitelist) that drift over
time and create surface for self-sabotage.

The app needs an explicit overlay deferral policy that lets the user postpone
the next overlay in bounded steps without turning deferral into a schedule
change, monitoring pause, or unlimited snooze. At the same time the settings
dialog must shrink to a small, intentional surface, and runtime-only options
should become fixed constants in code.

## What Changes

### Overlay deferral

- Replace the existing pause action with a contextual deferral control: a
  single menu item with a state-driven label.
- Add a one-way overlay deferral ladder for the active work period:
  `20 -> 10 -> 5 -> unavailable` (3 forced-order steps, in minutes).
- Apply a 2-minute cutoff before the currently scheduled next overlay; during
  the cutoff, and after the `+5` step is consumed, the deferral control
  remains visible but disabled with label `пора отдыхать`.
- Make each deferral add its duration to the currently scheduled next overlay
  time, not to the click time.
- Keep existing overlay cadence and lock escalation after overlays are shown;
  deferral only postpones the currently scheduled next overlay.

### Period settings freeze

- Persist deferral ladder state and current-period settings across app
  restarts until the next work period begins.
- Save settings changed during an active deferral period as pending period
  settings; they apply only from the next work period.
- The deferral period starts at the first overtime onset (`_overtime_started_at`
  becomes non-null) and ends at the next `is_work_time()` False -> True
  transition (computed against current-period settings).
- The `period_id` is the ISO datetime of the work_end that opened the period.

### Settings dialog

- Reduce user-visible settings to: `work_start`, `work_end`, `work_days`.
- Remove `notification_interval_min`, `overlay_delay_min`,
  `overlay_lock_initial_sec`, `overlay_lock_max_sec`, `work_apps` as
  user-editable fields. They become fixed constants in code:
  notification interval = 5 min, overlay delay = 20 min,
  lock_initial = 120 sec, lock_max = 1800 sec.
- Keep `calendar_source` and `calendar_cache_days` in config as hidden but
  active settings (not exposed in the dialog).
- Dialog shows two layouts:
  - Mode 1 (no active deferral period): single `Текущий` row per field,
    buttons `[Дефолт] [Сохранить]`.
  - Mode 2 (active deferral period): header banner stating that changes
    apply in the next work period with the computed start datetime;
    each field shows `Следующий / Текущий` row (editable) plus a
    `Было / —` row (read-only diff vs. snapshot at dialog open), buttons
    `[Дефолт] [Предыдущий] [Сохранить]`.
- Save in Mode 2 writes `pending_period_settings`; if the form matches
  `current_period_settings`, `pending_period_settings` is cleared.

### Contextual deferral control

- Single menu item with state-driven label and enabled state:
  - outside overtime: `Работаем!` (disabled)
  - overtime, ladder fresh: `Отложить на 20 мин` (enabled)
  - overtime, used `+20`: `Отложить на 10 мин` (enabled)
  - overtime, used `+20+10`: `Отложить на 5 мин` (enabled)
  - overtime, ladder exhausted: `пора отдыхать` (disabled)
  - overtime, within 2-min cutoff: `пора отдыхать` (disabled)

### Pause removal

- Remove the pause feature entirely: `pause_until` field, "Пауза на 1 ч"
  action, "Возобновить" item, the corresponding menu and IPC handlers.
- Monitoring no longer has a user-controlled pause path.

### Activity detection

- Remove the `work_apps` whitelist as a concept: `is_work_happening()` becomes
  "any user input or app activity" — keyboard, mouse, lid, focused-app
  presence — without filtering by app name.

## Capabilities

### New Capabilities

- `overlay-deferral`: Bounded, persistent deferral of the next overtime
  overlay through the contextual deferral control.
- `period-settings-freeze`: Current-period settings snapshot and pending
  period settings semantics across restarts and work-period boundaries.
- `activity-detection`: Definition of "user is working" as any local input
  or app activity, replacing the work-apps whitelist and removing the
  `is_paused` short-circuit.

### Modified Capabilities

- `responsive-status`: Settings saved during an active deferral period no
  longer apply to current enforcement within 10 seconds; only future-period
  settings change, while visible status still refreshes quickly. The pause
  menu item is removed; the contextual deferral control replaces it.
- `overlay-lock-escalation`: Lock durations become fixed constants
  (initial 120 sec, max 1800 sec). Overlay deferral postpones only the next
  overlay without replacing cadence or lock escalation; deferral saved
  during an active period takes effect immediately for the next overlay,
  while lock constants are not user-tunable.
- `settings-dialog-layout`: The dialog is reduced to schedule fields
  (`work_start`, `work_end`, `work_days`), shows a Mode 1 / Mode 2 split
  for current vs. pending edits, and replaces the old action buttons with
  `[Дефолт]`, `[Предыдущий]`, `[Сохранить]`.

## Impact

- `work_guard.py`: contextual deferral menu state, label state machine,
  next-overlay absolute time, deferral ladder persistence, current-period
  settings use, pause action removal, Swift status payload.
- `settings_dialog.py`: full rewrite of save flow, Mode 1 / Mode 2 rendering,
  banner for pending periods, three-row layout (`Следующий / Текущий`,
  `Было / —`) and the three-button toolbar.
- `config.py` and local store under `~/.config/work_guard/`: split into
  `current_period_settings`, `pending_period_settings`, `deferral` blocks;
  drop `pause_until`, `work_apps`, and the now-removed user-editable
  intervals/lock fields from DEFAULTS (lock seconds and notification
  interval become module-level constants).
- `monitor.py`: drop `is_paused`, drop `work_apps` filter; `is_work_happening`
  becomes "any input or app activity"; add next-work-period boundary
  detection for resetting deferral state and activating pending settings.
- `notifier.py`: untouched — it never read the dropped config fields.
  Notification cadence (`notification_interval_min`), overlay delay
  (`overlay_delay_min`) and lock bounds (`overlay_lock_initial_sec`,
  `overlay_lock_max_sec`) are read in `work_guard.py` (`_notification_interval`,
  `_overlay_delay_minutes`, `_overlay_lock_bounds`); they become module-level
  constants there.
- `production_calendar.py`: unchanged behaviour; `calendar_source` and
  `calendar_cache_days` continue to live in config but stay hidden from the
  dialog.
- OpenSpec specs for overtime status, overlay escalation, settings dialog,
  and the new deferral / settings-period capabilities.

## 1. Constants and configuration split

- [x] 1.1 Add module-level constants in `work_guard.py`: `OVERLAY_FIRST_DELAY_MIN = 20`, `LOCK_INITIAL_SEC = 120`, `LOCK_MAX_SEC = 1800`, `NOTIFY_INTERVAL_MIN = 5`, `LADDER_STEPS = [20, 10, 5]`, `DEFER_CUTOFF_SEC = 120`.
- [x] 1.2 Remove `pause_until`, `work_apps`, `notification_interval_min`, `overlay_delay_min`, `overlay_lock_initial_sec`, `overlay_lock_max_sec` from `config.DEFAULTS`.
- [x] 1.3 Define new `config.DEFAULTS` shape with `current_period_settings`, `pending_period_settings = None`, `deferral = None`, top-level `calendar_source`, `calendar_cache_days`.
- [x] 1.4 Replace `work_guard.py` callers `_notification_interval`, `_overlay_delay_minutes`, `_overlay_lock_bounds` with direct use of the new constants.

## 2. Config migration

- [x] 2.1 In `config.load`, detect legacy flat shape (no `current_period_settings` key).
- [x] 2.2 On legacy detect: write backup at `~/.config/work_guard/config.json.pre-deferral.bak` before any overwrite.
- [x] 2.3 Lift `work_start`, `work_end`, `work_days` from legacy flat into `current_period_settings`.
- [x] 2.4 Drop legacy fields (`pause_until`, `work_apps`, `notification_interval_min`, `overlay_delay_min`, `overlay_lock_initial_sec`, `overlay_lock_max_sec`) silently.
- [x] 2.5 Initialise `pending_period_settings = None`, `deferral = None`; preserve `calendar_source`, `calendar_cache_days` at top level.
- [x] 2.6 Persist migrated config immediately and emit one log line: `migration: legacy config detected, lifted into current_period_settings; pause/work_apps fields dropped`.

## 3. Deferral state machine

- [x] 3.1 Replace process-local `_next_overlay_minute`, `_next_overlay_delay_min`, `_overlay_base_delay_min`, `_next_overlay_lock_sec` with a single `_deferral` object backed by `config.deferral`.
- [x] 3.2 Initialise `deferral.period_id = isoformat(work_end_of_first_onset)`, `deferral.steps_consumed = []`, `deferral.next_overlay_at = _overtime_started_at + OVERLAY_FIRST_DELAY_MIN` on the first overtime onset of a period.
- [x] 3.3 Persist `deferral` after every mutation (onset, defer click, overlay fire).
- [x] 3.4 Add `defer_step()` action: validate state (in overtime, not at cutoff, ladder not exhausted), append `LADDER_STEPS[len(steps_consumed)]`, advance `next_overlay_at` by that many minutes, persist.
- [x] 3.7 Add step unlock delay: on defer click write `deferral.step_unlock_at = now + step * 3 // 4 minutes`; in `defer_step()` and `_contextual_button_state()` reject/disable if `now < step_unlock_at`. During delay show step title but `enabled: false`.
- [x] 3.5 In monitoring loop, fire overlay when `now >= next_overlay_at`; on fire, double cadence delay (existing logic), apply lock seconds doubled from `LOCK_INITIAL_SEC` up to `LOCK_MAX_SEC`, write new `next_overlay_at` (does not reset ladder).
- [x] 3.6 Add clock-jump guard: if `abs(next_overlay_at - now) > 24h` after restart, treat deferral as stale and reset (`deferral = None`).

## 4. Period boundary detection and promotion

- [x] 4.1 Track previous-tick `is_work_time()` value; on False→True transition under `current_period_settings`, run promotion: `current = pending if pending else current`, `pending = None`, `deferral = None`; persist in a single config write.
- [x] 4.2 On launch, recompute boundary: if `deferral != None` and `now >= next_work_start_after(period_id, current_period_settings)`, run the same atomic promotion.
- [x] 4.3 Implement helper `next_work_start_after(anchor_dt, settings) -> datetime` using `work_days`, `work_start`, and the production calendar.
- [x] 4.4 Implement helper `last_work_end_before(anchor_dt, settings) -> datetime` for period_id assignment on overtime onset.

## 5. Contextual button label state machine

- [x] 5.1 Add `_contextual_button_state()` returning `{title, enabled}` per spec rules: outside overtime → `("Работаем!", False)`; cutoff or ladder exhausted → `("пора отдыхать", False)`; step unlock delay active → `("Отложить на N мин", False)`; otherwise `(f"Отложить на {LADDER_STEPS[len(steps_consumed)]} мин", True)`.
- [x] 5.2 In `_status_json_payload`, replace the legacy pause/resume menu item with a single `defer_button` field carrying `{title, enabled}`.
- [x] 5.3 In `_status_json_payload`, drop legacy `paused` field and stop emitting pause-related menu items in `items`.

## 6. Swift menu agent update

- [x] 6.1 In `WorkGuardMenu/main.swift`, parse the new `defer_button: {title, enabled}` from `status.json`; render it as a single menu item.
- [x] 6.2 On click of the deferral menu item, write `command.json {"action": "defer", "ts": ...}`.
- [x] 6.3 Remove pause / resume rendering and pause / resume command emission from Swift.
- [x] 6.4 Add fallback: if `defer_button` field is missing in `status.json`, render the menu without the deferral item (do not crash).
- [x] 6.5 Rebuild Swift binary as part of the rebuild flow; verify the bundle launches and reads the new payload.

## 7. Pause feature removal in Python core

- [x] 7.1 Remove `toggle_pause`, `_pause_base_title`, `_refresh_pause_appearance`, and any other pause helpers from `work_guard.py`.
- [x] 7.2 Remove pause-related entries from the legacy menu builder (rumps fallback path).
- [x] 7.3 In `_handle_swift_command`, ignore `action="pause"` and `action="resume"` (defensive — older Swift may still send them) and add `action="defer"` routing to `defer_step()`.
- [x] 7.4 Remove `monitor.ActivityMonitor.is_paused` and any call sites that consult it.

## 8. Activity detection rewrite

- [x] 8.1 Extend or replace `KeyboardWatcher` with `InputWatcher` that listens to both `pynput.keyboard` and `pynput.mouse` events, updating a shared "last input" timestamp.
- [x] 8.2 Rewrite `monitor.ActivityMonitor.is_work_happening` as: any of (recent input, lid open + focused user-facing app); remove the `work_apps` whitelist filter entirely.
- [x] 8.3 Drop `work_apps` references in `monitor.py` (config getters, fallback handling).
- [x] 8.4 Confirm `LidWatcher` still gates the focused-app branch (lid closed → no activity from focused-app alone).

## 9. Settings dialog rewrite

- [x] 9.1 Reduce visible fields in `settings_dialog.py` to `work_start`, `work_end`, `work_days`. Remove every other field (lock seconds, notification interval, overlay delay, work apps, calendar source / cache).
- [x] 9.2 Implement two layout modes selected on open: Mode 1 (`pending == None` AND no active deferral period) and Mode 2 (active deferral period).
- [x] 9.3 Implement banner in Mode 2 with text `Изменения применятся в следующий рабочий период (начнётся: <weekday HH:MM>, <YYYY-MM-DD>)` computed from `next_work_start_after(now, current_period_settings)`.
- [x] 9.4 Implement per-field three-row layout in Mode 2: `Следующий / Текущий` editable row (pre-fill from `pending or current`), `Было / —` read-only row (snapshot of `current` taken at dialog open; render `—` when equal to editable).
- [x] 9.5 Implement button toolbars: `[Дефолт] [Сохранить]` in Mode 1, `[Дефолт] [Предыдущий] [Сохранить]` in Mode 2.
- [x] 9.6 Wire `[Дефолт]` to fill editable row from `config.DEFAULTS`.
- [x] 9.7 Wire `[Предыдущий]` to fill editable row from the dialog-open snapshot of `current_period_settings`.
- [x] 9.8 Wire `[Сохранить]`: Mode 1 writes form into `current_period_settings`, leaves `pending = None`; Mode 2 writes form into `pending_period_settings`, or sets `pending = None` if the form equals `current_period_settings` exactly.
- [x] 9.9 Add validation: disable `[Сохранить]` when `work_days` is empty or `work_start >= work_end`; show inline message under the affected field.

## 10. Tests and verification

- [x] 10.1 Unit test for the contextual button state machine across all states (outside overtime, fresh, used +20, used +20+10, used +20+10+5, cutoff window).
- [x] 10.2 Unit test for `defer_step`: time math (adds to scheduled, not click), ladder advance, cutoff rejection, ladder-exhaustion rejection.
- [x] 10.3 Unit test for period boundary detection: opens on first onset, closes on False→True transition; promotion atomicity (pending → current → null in one persisted write).
- [x] 10.4 Unit test for legacy config migration: backup written, lifted fields preserved, dropped fields gone, new keys initialised.
- [x] 10.5 Unit test for clock-jump guard: deferral reset when `abs(next_overlay_at - now) > 24h`.
- [x] 10.6 Integration test for restart-during-overtime: ladder and `next_overlay_at` survive process restart; period_id mismatch resets deferral.
- [x] 10.7 Manual test (cannot be automated): rebuild + relaunch via `bash rebuild.sh`, verify menu shows `Работаем!` outside overtime and `Отложить на 20 мин` once overtime begins; defer click cycles label through 10 → 5 → `пора отдыхать`; verify step unlock delay prevents rapid re-click.
- [x] 10.8 Manual test: open settings dialog in Mode 1 and Mode 2; verify banner, three-row layout, and that saved Mode 2 changes appear only after the next work-period boundary.
- [x] 10.9 Unit tests for step unlock delay: immediate re-click blocked, button disabled during delay, button enabled after 15/7 min, formula check (+20→15 min, +10→7 min).

## 11. Documentation

- [x] 11.1 Update `CLAUDE.md` and `AGENTS.md` Architecture section to reflect: new config shape, removed pause feature, removed work_apps, new constants location.
- [x] 11.2 Update `CONTEXT.md` glossary entries that mention the ladder shape (30→20→10→5 → 20→10→5) and any remaining references to pause as a user feature.
- [x] 11.3 Update `README.md` Features section: remove pause-related lines, add a short note about the deferral ladder.
- [x] 11.4 Update `docs/architecture/` C4 diagrams if any container/component changed (Swift IPC payload, pause removal).
- [x] 11.5 Add a one-line release note in the project changelog (if maintained) for users upgrading from a pause-aware build.

## Context

WorkGuard today exposes a flat `config.json` whose values are reloaded every
5 seconds and applied to enforcement immediately. The user can pause monitoring
through a menu action, edit any setting (work hours, lock seconds, overlay
delay, notification interval, work-apps whitelist), or restart the app to
reset escalating overlay state. Both pause and live-edit defeat the purpose
of after-hours guardrails.

`monitor.ActivityMonitor` decides "user is working" from a hard-coded keyboard
watcher plus the configured `work_apps` whitelist; `is_paused()` short-circuits
both. `work_guard.WorkGuardApp` keeps overtime escalation in process-local
fields (`_overtime_started_at`, `_minutes_overtime`, `_next_overlay_minute`,
`_next_overlay_delay_min`, `_next_overlay_lock_sec`) that are recomputed from
scratch each tick and lost on restart. The settings dialog (`settings_dialog.py`)
exposes every config field plus pause controls.

This change replaces that surface with a deferral-period policy: a frozen
snapshot of "rules in force right now", a separate "rules from next work day"
slot, and a forced-order ladder of overlay deferrals (20→10→5 minutes) that
persists across restarts and resets only when the next work period begins.
Pause is removed entirely; lock seconds, overlay delay, notification interval
and the work-apps whitelist become module constants or are deleted as user
concepts.

The change crosses Python core, the settings dialog, the on-disk store, and
the Swift menu agent payload. It also changes monitoring semantics (any input
counts as activity) and removes a user-facing feature (pause), so design-level
agreement is needed before touching code.

## Goals / Non-Goals

**Goals:**

- Make overtime enforcement deterministic against restarts and against
  settings edits during overtime.
- Give the user a bounded escape hatch (20→10→5 minute ladder) instead of an
  unlimited pause / snooze.
- Shrink the settings dialog to schedule fields only and freeze runtime knobs
  as constants in code.
- Make `is_work_happening()` "any user input or app activity", removing the
  fragile work-apps whitelist.
- Keep the Swift menu agent passive: it must render whatever state the Python
  core writes into `status.json`, including the new contextual button label
  and enabled flag, without learning about the deferral state machine.

**Non-Goals:**

- Cloud sync, server-side state, or multi-device coordination.
- Per-user / per-team policies — single-user macOS app stays single-user.
- Activity Signals collectors (browser, app-specific) — still future boundary.
- Visualising used ladder steps in the menu (one-line label only).
- Editing `calendar_source` / `calendar_cache_days` through the GUI; they
  remain hidden-but-active config fields.
- Localisation. Russian-only strings stay Russian-only.
- Reworking the overlay child process itself (`overlay.py`); we only change
  when it is launched and with what lock duration.

## Decisions

### Decision 1 — Deferral period span and identity

A **Deferral Period** opens at the first overtime onset
(`_overtime_started_at` becomes non-null) inside a work-day boundary and ends
on the next `is_work_time()` False → True transition computed against
`current_period_settings`. Its identifier is the ISO datetime of the work_end
that opened the period:

```
period_id = "2026-05-25T19:00:00"
```

On startup, the app reconstructs the period as follows:

```
load(config):
  if deferral != null:
    p_start = parse(deferral.period_id)
    p_end   = next_work_start_after(p_start, current_period_settings)
    if now < p_end:
      continue same period (preserve ladder + scheduled next_overlay_at)
    else:
      promote pending_period_settings -> current_period_settings (if any)
      deferral = null
```

**Alternatives considered:**

- ISO calendar date (`"2026-05-25"`): breaks for overtime that crosses
  midnight. Rejected.
- `_overtime_started_at` (timestamp of first onset): re-computable, but
  shifts with monitoring noise (lid close, brief idle). Rejected.
- Anonymous boolean flag: cannot detect "this is a stale period from a
  previous day" after a long sleep. Rejected.

The chosen identity makes a period a function of the schedule at the moment
the period opens, which is the same schedule used for all enforcement during
the period.

### Decision 2 — Settings snapshot split

`config.json` switches from a flat dict to three independent blocks plus
hidden infrastructure fields:

```json
{
  "current_period_settings": {
    "work_start": "09:00",
    "work_end":   "19:00",
    "work_days":  [1,2,3,4,5]
  },
  "pending_period_settings": null,
  "deferral": null,
  "calendar_source":     "xmlcalendar_ru",
  "calendar_cache_days": 30
}
```

Rules:

- All enforcement reads `current_period_settings` only.
- `pending_period_settings` is either `null` or a full snapshot of the three
  schedule fields with the same shape as `current_period_settings`. There is
  no diff/merge — it is always a complete snapshot.
- During the period transition the app sets
  `current_period_settings = pending_period_settings` and clears `pending`
  in a single write; if `pending` is `null`, `current` is unchanged.
- `calendar_source` and `calendar_cache_days` live at the top level. They
  apply immediately and are not snapshotted; users do not edit them through
  the dialog.
- `deferral` is `{period_id, steps_consumed, next_overlay_at}` or `null`.
- The deleted fields (`pause_until`, `work_apps`, `notification_interval_min`,
  `overlay_delay_min`, `overlay_lock_initial_sec`, `overlay_lock_max_sec`)
  are removed from DEFAULTS. The corresponding behaviour moves to module-level
  constants inside `work_guard.py` (which is where those values are read
  today, in `_notification_interval`, `_overlay_delay_minutes`, and
  `_overlay_lock_bounds`):
  `OVERLAY_FIRST_DELAY_MIN = 20`, `LOCK_INITIAL_SEC = 120`,
  `LOCK_MAX_SEC = 1800`, `NOTIFY_INTERVAL_MIN = 5`.
  `notifier.py` itself never read these fields, so it is not touched by this
  change.
  The 30 → 120 sec bump on `LOCK_INITIAL_SEC` is intentional: a 30-second
  lock is short enough to dismiss reflexively without the overlay registering
  as friction; 2 minutes is the minimum stretch where the user actually
  reads the message and decides. Cadence doubling (`LOCK_MAX_SEC = 1800`)
  is unchanged so peak lock duration still tops out at 30 minutes.

**Alternatives considered:**

- Single dict + per-field "pending" marker: surface complexity in every
  reader. Rejected.
- Versioned config with a write-ahead log: overkill for three fields.
  Rejected.

### Decision 3 — Ladder shape and state machine

The ladder is `[20, 10, 5]` in forced order. `deferral.steps_consumed` is the
ordered list of taken steps, e.g. `["+20"]`, `["+20","+10"]`,
`["+20","+10","+5"]`. The "next available step" is positional: step index =
`len(steps_consumed)`. Once index reaches 3 the ladder is exhausted.

`deferral.next_overlay_at` is an absolute ISO datetime initialised the first
tick the period opens:

```
deferral.next_overlay_at = _overtime_started_at + OVERLAY_FIRST_DELAY_MIN
```

A deferral click adds the step minutes to `next_overlay_at` (not to `now`)
and appends to `steps_consumed`. The overlay fires when `now >= next_overlay_at`;
on fire, the existing cadence doubling stays in place but writes the new
schedule back to `deferral.next_overlay_at` (so restart-after-overlay also
survives).

The 2-minute cutoff is:

```
defer_enabled = (now < next_overlay_at - 2 minutes)
                AND len(steps_consumed) < 3
                AND in_overtime
```

**Alternatives considered:**

- Free choice of step (any unused step at any time): breaks the
  "progressively smaller" guarantee in CONTEXT.md. Rejected.
- Counter (`int`) instead of list: loses replay history for debugging and
  cannot encode "skipped step" if we later allow it. List is the same size
  on disk and is read-friendly. Kept.
- Storing `next_overlay_at` as minute counter: cannot survive restart
  without recomputing `_overtime_started_at` (which is itself unstable).
  Rejected.

### Decision 4 — Contextual button label state machine

The contextual control is a single `rumps` menu item whose `title` and
`enabled` change each tick. Logic (executed in `_status_json_payload`):

```
if not in_overtime:
    title, enabled = "Работаем!", False
elif now >= (deferral.next_overlay_at - 2 minutes):
    title, enabled = "пора отдыхать", False
elif len(steps_consumed) >= 3:
    title, enabled = "пора отдыхать", False
else:
    step = LADDER[len(steps_consumed)]    # 20, 10, or 5
    title, enabled = f"Отложить на {step} мин", True
```

`status.json` exposes `defer_button: {title, enabled}` so the Swift menu
agent can render it without re-implementing the rules. Click → Swift writes
`command.json {"action": "defer", "ts": ...}` → Python core consumes it,
appends to ladder, advances `next_overlay_at`, persists.

**Alternatives considered:**

- Submenu listing all four states with separate items: contradicts the
  "Contextual Pause Control = single position" rule in CONTEXT.md. Rejected.
- Putting the deferral button inside the overlay itself: contradicts
  CONTEXT.md (`Overlay Deferral is controlled from the menu, not from the
  overlay`). Rejected.

### Decision 5 — Settings dialog UI shape

The dialog renders one of two layouts based on whether
`pending_period_settings != null` OR an active deferral period exists at
the time the dialog opens.

**Mode 1 (no active deferral period):**

```
field-row layout:
  label
       Текущий: [editable input]
buttons: [Дефолт]  [Сохранить]
```

`Сохранить` writes the form values back to `current_period_settings`
directly; `pending_period_settings` stays `null`.

**Mode 2 (active deferral period):**

```
banner: "Изменения применятся в следующий рабочий период
         (начнётся: <weekday> <HH:MM>, <YYYY-MM-DD>)"
field-row layout:
  label
       Следующий / Текущий: [editable input]   (= pending or current)
       Было / —:            <was value>        (= current at dialog open,
                                                  or "—" if equal to editable)
checkbox-row layout (work_days):
  label
                       ПН  ВТ  СР  ЧТ  ПТ  СБ  ВС
       Следующий / Текущий: [☑] [☑] [☑] [☑] [☑] [☐] [☐]   (editable)
       Было / —:            [☑] [☑] [☑] [☑] [☑] [☐] [☐]   (or row of "—")
buttons: [Дефолт]  [Предыдущий]  [Сохранить]
```

- `Сохранить` writes form values to `pending_period_settings`. If the form
  matches `current_period_settings` exactly, write `pending = null` instead
  (clean state, no banner next time).
- `Предыдущий` resets the editable row to the "Было" values (which equal
  `current_period_settings` at dialog open).
- `Дефолт` resets the editable row to `config.DEFAULTS`.
- `Было / —` shows the snapshot of `current_period_settings` taken when the
  dialog opened. If a field's "Было" equals its editable value, the entire
  "Было" cell renders as `—`; for the days checkbox row it renders as a row
  of `—` placeholders so columns align.
- Banner datetime is computed as `next_work_start_after(now, current)`.

**Alternatives considered:**

- Modal "are you sure these changes are pending?" before save: extra click,
  banner already communicates intent. Rejected.
- Persistent menu status hint about pending changes: CONTEXT.md explicitly
  rejects this. Rejected.
- Diff-style save (only edited fields): user cannot see the full picture of
  "what will the next period look like", and the data model becomes harder
  to reason about. Rejected.

### Decision 6 — Activity detection without work_apps

`monitor.ActivityMonitor.is_work_happening()` becomes "any of: keyboard
event seen recently, mouse event seen recently, lid open, currently focused
app changed within the activity window". The work-apps whitelist is deleted.
Concretely:

- `KeyboardWatcher` stays as-is.
- A new `InputWatcher` (or extension of `KeyboardWatcher`) listens to
  `pynput.mouse` as well.
- The focused-app check replaces the whitelist read.
- `LidWatcher` still gates "user is at the machine".

This eliminates the only way users currently sidestep monitoring (renaming
or excluding apps).

**Alternatives considered:**

- Keep whitelist but hide from UI: silent dead weight in code. Rejected.
- Per-app focus history: future Activity Signals territory, out of scope.
  Rejected.

### Decision 7 — Pause feature removal

The pause action, `pause_until` field, "Пауза на 1 ч" / "Возобновить" menu
items, and Swift `pause`/`resume` commands are removed. `monitor.is_paused`
disappears. The contextual button replaces the old pause menu slot.

This is a behaviour change: users who previously used pause for legitimate
short breaks now experience normal idle handling (no input → no overtime
accrued) rather than an explicit pause control. Acceptable per CONTEXT.md
position that the **Contextual Pause Control** is the only menu control in
that menu region.

## Risks / Trade-offs

[Risk] Users who relied on pause to stop accidental overtime accrual during
long meetings (no keyboard activity but app open) may now still accrue
overtime if a watched app remains focused and mouse moves. → Mitigation:
"any input" now includes mouse; with no input at all, idle-based logic
already stops counting. The remaining loss is intentional — pause was the
self-sabotage vector this change closes.

[Risk] Removing `work_apps` whitelist increases false-positive overtime
detection (e.g. user reading Slack in evening). → Mitigation: this matches
the stated product intent ("any work-like activity"); user can still defer
via the ladder. Documented in CONTEXT.md.

[Risk] If `current_period_settings.work_start` is changed to a value that
never occurs again (e.g. `work_days = []`), the next-period transition can
never fire, freezing the deferral forever. → Mitigation: dialog validates
`work_days` non-empty before allowing Save; same for `work_start < work_end`.

[Risk] On first upgrade, existing `config.json` is flat with old fields.
A naive load would lose data. → Mitigation: see Migration Plan; loader
detects flat shape, lifts `work_*` into `current_period_settings`, drops
removed fields silently.

[Risk] `deferral.next_overlay_at` is an absolute timestamp; if the system
clock jumps (DST, NTP correction) the next overlay can fire earlier/later
than expected. → Mitigation: tolerate up to one DST hour; on detect of
`abs(next_overlay_at - now) > 24h`, treat ladder as stale and reset
deferral (same as period transition).

[Risk] The Swift menu agent caches `status.json` shape; adding `defer_button`
without updating Swift means the new label never renders, breaking UX. →
Mitigation: bump status payload version; Swift falls back to plain "WorkGuard"
title if `defer_button` missing. Update Swift in the same change.

[Risk] Removing pause silently breaks user muscle memory. → Mitigation:
ship a one-shot release note in the README and CONTEXT.md; on first run
after upgrade, log "pause feature removed; deferral ladder available
during overtime" once.

[Risk] The forced 20/10/5 ladder is shorter than the proposal's original
30/20/10/5. Users who tested the old design may complain. → Mitigation:
documented decision; total maximum deferral remains 35 minutes per period
(vs old 65), which is intentionally tighter.

## Migration Plan

1. **Loader compatibility shim** in `config.load`:
   - If `current_period_settings` key absent → treat file as flat legacy.
   - Lift `work_start`, `work_end`, `work_days` into a new
     `current_period_settings` dict.
   - Drop `pause_until`, `work_apps`, `notification_interval_min`,
     `overlay_delay_min`, `overlay_lock_initial_sec`, `overlay_lock_max_sec`
     silently (no warning — they no longer exist as user knobs).
   - Keep `calendar_source`, `calendar_cache_days` at top level.
   - Initialise `pending_period_settings = null`, `deferral = null`.
   - Persist immediately so the on-disk file is in new shape.

2. **First-run after upgrade**:
   - LaunchAgent already restarts the app on next login. No user action
     required.
   - One log line: `migration: legacy config detected, lifted into
     current_period_settings; pause/work_apps fields dropped`.

3. **Rollback**: keep a one-shot backup at
   `~/.config/work_guard/config.json.pre-deferral.bak` written by the
   loader before the first overwrite. Manual restore is the rollback path
   for users who want the old shape.

4. **Swift agent**: rebuilt and shipped as part of the same `rebuild.sh`
   run. Bundle ID is stable, no LaunchAgent re-registration needed.

5. **No DB / no remote state**, so the rest of the migration is a no-op.

## Open Questions

- **`work_days` empty validation message**: text and placement still to be
  decided in implementation (inline below row vs. error banner). Default to
  disabling Save with a tooltip until validation passes.
- **`test_overlay` debug menu item**: keep as-is (it bypasses ladder and
  cutoff for diagnostics). Confirm during tasks.
- **Notification interval constant value**: kept at 5 min for parity with
  current default. Adjust if telemetry shows different rhythm needed
  (future, out of scope).
- **Banner datetime weekday localisation**: render Russian weekday
  abbreviations (ПН/ВТ/...) directly in the dialog; no `locale` dependency
  required since the rest of the app strings are Russian-only.
- **Clock-jump handling**: 24-hour threshold above is a heuristic; consider
  refining once real-world data exists.

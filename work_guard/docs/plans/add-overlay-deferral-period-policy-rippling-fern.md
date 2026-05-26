# Plan: add-overlay-deferral-period-policy

## Context

WorkGuard's current pause mechanism is a 1-hour hard toggle stored in `pause_until`. Users
wanting repeated overtime deferrals must re-engage the menu every hour. This change replaces
pause with a **deferral ladder** `[20, 10, 5]` minutes consumed in order, persisted as
`deferral` in config, scoped to a **period** (work_end → next work-period start). Settings
are split into `current_period_settings` / `pending_period_settings` so changes during
overtime take effect only at the next period boundary. The `work_apps` whitelist and all
user-tunable timing knobs are removed; `work_start/end/days` are the only user-editable
fields.

## Critical Files

| File | Change type |
|------|-------------|
| `config.py` | New DEFAULTS shape, migration logic |
| `work_guard.py` | Constants, remove pause, add deferral state machine + period boundary + button state + status payload |
| `monitor.py` | Remove `is_paused`, remove `work_apps`, add mouse to `InputWatcher` |
| `settings_dialog.py` | 3-field only, Mode 1 / Mode 2 |
| `WorkGuardMenu/main.swift` | Parse `defer_button`, remove pause/resume items |
| `tests/test_deferral.py` (new) | Unit + integration tests |
| `CLAUDE.md`, `AGENTS.md`, `CONTEXT.md`, `README.md` | Doc updates |

---

## Implementation Order

### Phase 1 — Config foundation (tasks 1–10)

**1. `config.py` — new DEFAULTS + migration**

New `DEFAULTS` shape:
```python
DEFAULTS = {
    "current_period_settings": {
        "work_start": "09:00",
        "work_end":   "19:00",
        "work_days":  [1, 2, 3, 4, 5],
    },
    "pending_period_settings": None,
    "deferral": None,
    "calendar_source": "xmlcalendar_ru",
    "calendar_cache_days": 30,
}
```
Drop from DEFAULTS: `pause_until`, `work_apps`, `notification_interval_min`,
`overlay_delay_min`, `overlay_lock_initial_sec`, `overlay_lock_max_sec`.

In `config.load()`, detect legacy shape (`"current_period_settings" not in cfg`):
- Write backup `~/.config/work_guard/config.json.pre-deferral.bak`
- Lift `work_start`, `work_end`, `work_days` → `current_period_settings`
- Drop legacy fields silently
- Set `pending_period_settings = None`, `deferral = None`
- Persist immediately; emit one log line

**2. `work_guard.py` — add module-level constants**
```python
OVERLAY_FIRST_DELAY_MIN = 20
LOCK_INITIAL_SEC        = 120
LOCK_MAX_SEC            = 1800
NOTIFY_INTERVAL_MIN     = 5
LADDER_STEPS            = [20, 10, 5]
DEFER_CUTOFF_SEC        = 120
```
Replace callers `_notification_interval`, `_overlay_delay_minutes`,
`_overlay_lock_bounds` with these constants.

---

### Phase 2 — Remove pause; simplify monitor (tasks 7, 29–36)

**3. `monitor.py` — remove pause path, remove work_apps, add mouse**

- Delete `is_paused()` and all callers
- Delete `is_work_app_active()` and `work_apps` config reads
- Rename `KeyboardWatcher` → `InputWatcher`; subscribe to both
  `pynput.keyboard` and `pynput.mouse.Listener`; update shared
  `_last_input_at` timestamp
- Rewrite `is_work_happening()`:
  ```python
  def is_work_happening(self):
      recent_input = (now - self._last_input_at) < ACTIVITY_WINDOW_SEC
      return recent_input or (self._lid_open and self._has_focused_app())
  ```
  Remove `work_apps` branch entirely; `LidWatcher` still gates focused-app branch

**4. `work_guard.py` — remove pause helpers**

Delete: `toggle_pause`, `_pause_base_title`, `_refresh_pause_appearance`, all
pause-related menu entries in the rumps fallback path.

In `_handle_swift_command`: ignore `action="pause"` / `action="resume"` (no-op,
defensive); route `action="defer"` to `defer_step()`.

---

### Phase 3 — Deferral state machine + period boundary (tasks 11–20)

**5. Deferral state (`work_guard.py`)**

Replace four scattered instance vars (`_next_overlay_minute`, `_next_overlay_delay_min`,
`_overlay_base_delay_min`, `_next_overlay_lock_sec`) with a single `_deferral` dict
backed by `config["deferral"]`. Shape:
```python
{
    "period_id":      "2026-05-26T19:00:00",   # ISO of work_end that opened period
    "steps_consumed": [],                        # e.g. ["+20", "+10"]
    "next_overlay_at": "2026-05-26T19:20:00",  # ISO datetime
}
```

**On first overtime onset** of a period:
```python
deferral["period_id"]      = isoformat(last_work_end_before(now, current_period_settings))
deferral["steps_consumed"] = []
deferral["next_overlay_at"] = _overtime_started_at + OVERLAY_FIRST_DELAY_MIN minutes
config["deferral"] = deferral; config.save()
```

**`defer_step()` action:**
- Validate: in overtime, not at cutoff (`(next_overlay_at - now) > DEFER_CUTOFF_SEC`),
  ladder not exhausted (`len(steps_consumed) < len(LADDER_STEPS)`)
- `step = LADDER_STEPS[len(steps_consumed)]`
- `next_overlay_at += step minutes`
- `steps_consumed.append(f"+{step}")`
- Persist

**Monitoring loop — overlay fire:**
- When `now >= next_overlay_at`: show overlay; double cadence delay (`_next_overlay_delay_min *= 2`);
  double lock secs from `LOCK_INITIAL_SEC` up to `LOCK_MAX_SEC`; write new `next_overlay_at`
  (does NOT reset ladder)

**Clock-jump guard on restart:**
```python
if abs((next_overlay_at - now).total_seconds()) > 86400:
    config["deferral"] = None; config.save()
```

**6. Period boundary helpers (`work_guard.py`)**

```python
def last_work_end_before(anchor_dt, settings) -> datetime:
    # walk backwards from anchor_dt to find last work_end on a work_day
    # use production_calendar for holiday awareness

def next_work_start_after(anchor_dt, settings) -> datetime:
    # walk forward from anchor_dt to find next work_start on a work_day
```

**Period boundary detection in `_tick()`:**

Track `_prev_tick_is_work_time` (bool, init None). On `False → True` transition:
```python
if config["pending_period_settings"] is not None:
    config["current_period_settings"] = deepcopy(config["pending_period_settings"])
config["pending_period_settings"] = None
config["deferral"] = None
config.save()  # single write
```

**On launch:** if `deferral != None` and `now >= next_work_start_after(period_id, current_period_settings)`,
run same atomic promotion.

---

### Phase 4 — Contextual button + Swift IPC (tasks 21–28)

**7. `_contextual_button_state()` in `work_guard.py`**

```python
def _contextual_button_state(self):
    if not self._in_overtime():
        return {"title": "Работаем!", "enabled": False}
    d = config["deferral"]
    if d is None:
        return {"title": "Работаем!", "enabled": False}
    steps = d["steps_consumed"]
    next_at = parse_iso(d["next_overlay_at"])
    secs_left = (next_at - now).total_seconds()
    if len(steps) >= len(LADDER_STEPS) or secs_left <= DEFER_CUTOFF_SEC:
        return {"title": "пора отдыхать", "enabled": False}
    minutes = LADDER_STEPS[len(steps)]
    return {"title": f"Отложить на {minutes} мин", "enabled": True}
```

**8. `_status_json_payload()` changes**

- Add `"defer_button": self._contextual_button_state()`
- Remove `"paused"` field
- Replace pause/resume items in `items` list with nothing (defer_button is the only
  new control; it lives at the top level, not in `items`)

**9. `WorkGuardMenu/main.swift`**

- Parse `defer_button: {title, enabled}` from status.json
- Render as single menu item; on click write `{"action": "defer", "ts": ...}`
- Remove all pause/resume rendering and command emission
- Fallback: if `defer_button` absent, render menu without it (no crash)
- `rebuild.sh` step builds Swift binary; verify bundle launches

---

### Phase 5 — Settings dialog (tasks 37–45)

**10. `settings_dialog.py` rewrite**

Reduce to 3 editable fields: `work_start`, `work_end`, `work_days`.
Remove all other fields.

Mode detection on `open()`:
```python
active_deferral = config["deferral"] is not None
# Mode 1: active_deferral == False
# Mode 2: active_deferral == True
```

**Mode 1 layout:**
- Single editable row per field labeled `Текущий`
- Buttons: `[Дефолт]` `[Сохранить]`
- Save → write to `current_period_settings`, leave `pending = None`

**Mode 2 layout:**
- Banner: `Изменения применятся в следующий рабочий период (начнётся: <weekday HH:MM>, <YYYY-MM-DD>)`
  computed from `next_work_start_after(now, current_period_settings)`
- Two rows per field:
  - Editable `Следующий / Текущий` — pre-fill from `pending or current`
  - Read-only `Было / —` — snapshot of `current` at open; render `—` when equal
- Buttons: `[Дефолт]` `[Предыдущий]` `[Сохранить]`
- `[Дефолт]` → fill editable from `DEFAULTS`
- `[Предыдущий]` → fill editable from dialog-open snapshot of `current`
- Save: if form != current → write to `pending_period_settings`; if form == current → set `pending = None`

**Validation (both modes):**
- Disable `[Сохранить]` when `work_days` empty OR `work_start >= work_end`
- Show inline error under affected field

Settings dialog preserves fields it doesn't edit: `calendar_source`, `calendar_cache_days`,
`pending_period_settings` (when not saving), `deferral`.

---

### Phase 6 — Tests (tasks 46–53)

New file: `tests/test_deferral.py`

Tests to write:
- **Button state machine**: outside overtime, fresh ladder, after +20, after +20+10, after
  +20+10+5, cutoff window → correct `{title, enabled}`
- **`defer_step()` time math**: adds to scheduled time not click time; ladder advance;
  cutoff rejection; ladder-exhaustion rejection
- **Period boundary**: deferral opens on first onset; closes on False→True; promotion is
  atomic (pending→current→null in single write)
- **Legacy migration**: backup written; lifted fields preserved; dropped fields gone;
  new keys initialised
- **Clock-jump guard**: `abs(next_overlay_at - now) > 24h` → deferral reset
- **Integration restart**: ladder + `next_overlay_at` survive restart; period_id mismatch
  resets deferral

---

### Phase 7 — Documentation (tasks 54–58)

- `CLAUDE.md` + `AGENTS.md`: update Architecture section (new config shape, removed pause,
  removed work_apps, constants location)
- `CONTEXT.md`: fix ladder shape references (30→20→10→5 → 20→10→5), remove pause as user feature
- `README.md`: remove pause lines, add deferral ladder note
- `docs/architecture/`: update C4 if Swift IPC payload or pause container changed
- Changelog note for users upgrading from pause-aware build

---

## Reuse Map

| What | Where |
|------|-------|
| `production_calendar.py` calendar lookup | reuse in `next_work_start_after` / `last_work_end_before` |
| `config.save()` | call after every deferral mutation |
| `_show_overlay(lock_sec)` | existing, call unchanged; pass computed `lock_sec` |
| `pynput.mouse.Listener` | add alongside existing `pynput.keyboard.Listener` in `InputWatcher` |

---

## Verification

1. **Unit tests:** `conda run -n work_guard python -m pytest tests/test_deferral.py -v`
2. **Manual Mode 1:** `conda run -n work_guard python settings_dialog.py` outside overtime → 3 fields, two buttons, save writes `current_period_settings`
3. **Manual Mode 2:** trigger overtime (set `work_end` to past) → open settings → banner shows next-period start, three-row layout, save writes `pending_period_settings`
4. **Manual defer ladder:** `bash rebuild.sh`; wait for overtime; verify menu shows `Отложить на 20 мин` → click → `Отложить на 10 мин` → click → `Отложить на 5 мин` → click → `пора отдыхать` (disabled)
5. **Manual restart:** defer +20 during overtime, kill and relaunch → ladder position and `next_overlay_at` preserved
6. **Legacy migration:** rename `config.json` to contain old flat shape → launch → backup written, new shape in place

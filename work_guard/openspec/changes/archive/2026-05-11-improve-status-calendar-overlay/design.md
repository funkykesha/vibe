## Context

WorkGuard is a macOS menu bar utility with a Python `rumps` core, a Swift menu-bar helper, a Tk settings subprocess, and a PyObjC overlay subprocess. The current monitoring loop sleeps for 60 seconds and increments overtime by one per loop, so user-visible status can lag and overtime accounting is coupled to tick cadence. Workday detection only uses configured weekdays, so Russian holidays, transferred workdays, and shortened workdays are not represented. Overlay lock duration is always 30 seconds. The Tk settings dialog uses fixed non-resizable layout and can clip the save button on macOS.

## Goals / Non-Goals

**Goals:**

- Refresh visible status quickly without inflating overtime minutes.
- Compute working days from xmlcalendar.ru Russian production-calendar JSON, including holidays, transferred workdays, and shortened workdays.
- End shortened workdays one hour earlier than the configured normal work end.
- Cache yearly calendar data so the app keeps working offline.
- Double overlay lock duration on each overlay, capped by a configurable maximum defaulting to 30 minutes.
- Expose overlay lock duration settings in the settings dialog.
- Make settings dialog height adapt to its content so action buttons are fully visible.

**Non-Goals:**

- Supporting countries other than Russia in this change.
- Replacing the current menu-bar implementation or Swift IPC shape.
- Adding network access during every monitoring tick.
- Adding a full calendar editor for manual holiday overrides.
- Changing notification escalation messages or ASCII art content.

## Decisions

1. **Use a fast UI loop with elapsed-time accounting.**
   - The monitor loop should run frequently enough for status to feel current, such as every 5 seconds.
   - Overtime minutes should be derived from a timestamp marking when after-hours work began, not from number of loop iterations.
   - Rationale: lowering `CHECK_INTERVAL` alone would otherwise make overtime and notifications advance too quickly.
   - Alternative considered: keep 60-second loop and add ad hoc refresh calls. Rejected because config reload, status, and Swift payload would still have multiple update paths.

2. **Use xmlcalendar.ru as the Russian production-calendar source with yearly cache files.**
   - Fetch `https://xmlcalendar.ru/data/ru/<year>/calendar.json`.
   - Store parsed or raw yearly data under `~/.config/work_guard/`.
   - Use cache first when fresh enough, fetch when missing or stale, and fall back to weekday rules if neither network nor cache is available.
   - Rationale: xmlcalendar.ru includes official transfers and shortened days, which generic holiday libraries may miss.
   - Alternative considered: Python `holidays` library. Rejected for this change because transferred workdays and shortened workdays are central requirements.

3. **Map xmlcalendar day markers to WorkGuard day types.**
   - No suffix: non-working holiday/weekend.
   - `+`: transferred working day, even if it falls on a configured non-work weekday.
   - `*`: shortened working day, with effective `work_end` one hour earlier.
   - Missing date in calendar data: fall back to configured `work_days`.
   - Rationale: this matches the production-calendar semantics the app needs while keeping existing weekly config useful.

4. **Keep overlay trigger delay and overlay lock duration separate.**
   - `overlay_delay_min` continues to control when overlays appear.
   - New config fields control lock duration, such as `overlay_lock_initial_sec` and `overlay_lock_max_sec`.
   - Lock duration doubles per overlay shown and is capped at `overlay_lock_max_sec`, default 1800 seconds.
   - Reset lock escalation when overtime session resets.
   - Rationale: users asked to increase display/lock time, while existing delay escalation already controls when overlays repeat.

5. **Use adaptive Tk sizing rather than fixed geometry.**
   - Keep the dialog visually compact but let Tk compute requested height.
   - Set `minsize` after `update_idletasks()` and allow vertical resizing if content or platform metrics need more space.
   - Put action buttons in a bottom frame with explicit padding.
   - Rationale: macOS Tk font/control metrics vary; fixed non-resizable windows clip controls.

## Risks / Trade-offs

- **Network fetch fails** → Use cached data; if no cache exists, fall back to existing weekday schedule and log a warning.
- **xmlcalendar format changes** → Keep parser small, validate expected `year`/`months`/`days`, and fail closed to cache/fallback instead of crashing.
- **Fast tick increases CPU use** → Keep per-tick work cheap, avoid network in tick path, and reuse cached parsed calendar data.
- **Shortened day crosses edge cases near midnight** → Limit current behavior to same-day `HH:MM` schedules; preserve existing behavior for invalid times.
- **Long overlay locks become too aggressive** → Cap at configurable maximum, default 30 minutes, and reset escalation when user returns to work time, stops working, or pauses.
- **Settings dialog grows too large later** → Adaptive sizing and optional vertical resizing reduce clipping risk without redesigning the UI.

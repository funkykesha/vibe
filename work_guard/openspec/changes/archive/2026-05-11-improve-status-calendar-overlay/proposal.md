## Why

WorkGuard currently updates user-visible status too slowly, treats workdays only as a weekly mask, uses a fixed overlay lock duration, and can render the settings dialog with the save button clipped. These issues make the app feel stale, misclassify Russian holidays and transferred workdays, and block users from configuring the new escalation behavior.

## What Changes

- Refresh menu/status state quickly while keeping overtime accounting based on elapsed time rather than tick count.
- Add Russian production-calendar support using xmlcalendar.ru yearly JSON data, including holidays, transferred workdays, and shortened workdays.
- Treat shortened workdays as ending one hour earlier than the configured normal work end.
- Escalate overlay lock duration by doubling each shown overlay, capped by a configurable maximum that defaults to 30 minutes.
- Add settings for initial overlay lock duration and maximum overlay lock duration.
- Make the settings dialog size itself to its content so action buttons remain fully visible.

## Capabilities

### New Capabilities

- `responsive-status`: Fast status refresh and elapsed-time overtime accounting.
- `production-calendar`: Russian production calendar support with holidays, transferred workdays, and shortened workdays.
- `overlay-lock-escalation`: Configurable overlay lock duration escalation with a maximum cap.
- `settings-dialog-layout`: Settings dialog sizing that keeps all controls visible.

### Modified Capabilities

- None.

## Impact

- `work_guard.py`: monitoring loop cadence, elapsed overtime accounting, overlay lock duration state, Swift status payload timing.
- `monitor.py`: work-time calculation using production calendar data.
- `config.py`: new defaults for calendar source/cache and overlay lock durations.
- `settings_dialog.py`: new configuration fields and adaptive window sizing.
- `overlay.py`: existing `lock_secs` argument remains the execution path for lock duration.
- `requirements.txt`: likely new dependency for HTTP fetch if standard library is not sufficient; prefer standard library unless a dependency is clearly justified.
- Runtime data under `~/.config/work_guard/`: yearly calendar cache files.
- README and architecture docs: updated behavior and configuration semantics.

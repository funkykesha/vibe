# Tasks

## 1. Remove viewing signals from the monitor
- [x] 1.1 In `engagement_monitor.py` `update()`, remove the frontmost-app engagement branch (the `active_app == frontmost` bump).
- [x] 1.2 In `engagement_monitor.py` `update()`, remove the browser-history branch (`self._reader.last_visit(...)` bump).
- [x] 1.3 Keep the `active_app` parameter in `update()` (caller compatibility); mark it intentionally unused, do not touch the call site in `work_guard.py`.
- [x] 1.4 Explicitly suppress the now-unused `active_app` inside `update()` (e.g. leading `_ = active_app` or a one-line comment) so linters do not flag it.

## 2. Remove the browser-history collaborator
- [x] 2.1 Remove `self._reader = BrowserHistoryReader(...)` from `TodoistEngagementMonitor.__init__`.
- [x] 2.2 Remove the `self._reader.update_browsers(...)` line from `update_config()`.
- [x] 2.3 Remove the `BrowserHistoryReader` import in `engagement_monitor.py`.

## 3. Delete dead browser-history code
- [x] 3.1 Remove the `BrowserHistoryReader` class from `todoist_signals.py`.
- [x] 3.2 Remove all reader-only dead code in `todoist_signals.py`: the `_BROWSER_HISTORY_PATHS` constant, the `_HISTORY_THROTTLE_SEC` constant, and the `_chrome_time_to_dt` helper (used only by `BrowserHistoryReader`).
- [x] 3.3 Confirm `TodoistApiClient` and shared helpers (`_parse_iso`, etc.) remain intact; grep that no removed symbol is still referenced.

## 4. Update docs/comments
- [x] 4.1 Update the `engagement_monitor.py` module docstring to describe a single API engagement signal.
- [x] 4.2 Update the `todoist_signals.py` module docstring to drop the browser-history reader mention.
- [x] 4.3 Update the capability spec Purpose line (at sync/archive) from "three local signals" to the single API signal.

## 5. Verify
- [x] 5.1 `bash rebuild.sh`; launch with `TODOIST_API_TOKEN` set.
- [x] 5.2 Confirm completing/adding a task advances `last_engagement` (API signal works).
- [x] 5.3 Confirm opening the Todoist app and visiting `todoist.com` do NOT advance `last_engagement`.
- [x] 5.4 Confirm with no token: feature stays enabled, reminder still fires on threshold, no engagement advance, no crash, no history DB access.
- [x] 5.5 Confirm both module docstrings (`engagement_monitor.py`, `todoist_signals.py`) describe a single API engagement signal with no browser-history / frontmost-app mention left.
- [x] 5.6 `openspec validate restrict-todoist-engagement-to-api --strict` passes.

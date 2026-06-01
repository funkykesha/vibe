# Tasks

## 1. Remove viewing signals from the monitor
- [ ] 1.1 In `engagement_monitor.py` `update()`, remove the frontmost-app engagement branch (the `active_app == frontmost` bump).
- [ ] 1.2 In `engagement_monitor.py` `update()`, remove the browser-history branch (`self._reader.last_visit(...)` bump).
- [ ] 1.3 Keep the `active_app` parameter in `update()` (caller compatibility); mark it intentionally unused, do not touch the call site in `work_guard.py`.

## 2. Remove the browser-history collaborator
- [ ] 2.1 Remove `self._reader = BrowserHistoryReader(...)` from `TodoistEngagementMonitor.__init__`.
- [ ] 2.2 Remove the `self._reader.update_browsers(...)` line from `update_config()`.
- [ ] 2.3 Remove the `BrowserHistoryReader` import in `engagement_monitor.py`.

## 3. Delete dead browser-history code
- [ ] 3.1 Remove the `BrowserHistoryReader` class from `todoist_signals.py`.
- [ ] 3.2 Remove the Chromium history DB path constants used only by that class.
- [ ] 3.3 Confirm `TodoistApiClient` and shared helpers (`_parse_iso`, etc.) remain intact.

## 4. Update docs/comments
- [ ] 4.1 Update the `engagement_monitor.py` module docstring to describe a single API engagement signal.
- [ ] 4.2 Update the `todoist_signals.py` module docstring to drop the browser-history reader mention.
- [ ] 4.3 Update the capability spec Purpose line (at sync/archive) from "three local signals" to the single API signal.

## 5. Verify
- [ ] 5.1 `bash rebuild.sh`; launch with `TODOIST_API_TOKEN` set.
- [ ] 5.2 Confirm completing/adding a task advances `last_engagement` (API signal works).
- [ ] 5.3 Confirm opening the Todoist app and visiting `todoist.com` do NOT advance `last_engagement`.
- [ ] 5.4 Confirm with no token: feature stays enabled, reminder still fires on threshold, no engagement advance, no crash, no history DB access.
- [ ] 5.5 `openspec validate restrict-todoist-engagement-to-api --strict` passes.

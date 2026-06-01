## Context

`TodoistEngagementMonitor` (`engagement_monitor.py`) folds three local signals into one `last_engagement` timestamp:
1. frontmost app `== Todoist` (`update()`, lines ~74-77);
2. last `todoist.com` visit from Chromium history via `BrowserHistoryReader` (`update()`, lines ~79-82; reader built in `__init__`, refreshed in `update_config`);
3. Todoist REST API task changes via `TodoistApiClient`, polled in a background thread.

This change removes signals 1 and 2, leaving the API as the sole engagement source. The API poll path, threshold/cadence gating, snapshot persistence, and the overlay are untouched. The edit is deliberately a deletion, not a rewrite: drop two branches and one collaborator.

## Goals / Non-Goals

**Goals:**
- `last_engagement` advances only from API-observed user task changes.
- WorkGuard no longer reads the frontmost application name or any Chromium history database.
- Token becomes the gate for all engagement detection; without it, no signal advances the timer.

**Non-Goals:**
- No change to the API client, polling cadence, lookback window, or System-Change classification.
- No change to the threshold/repeat-cadence reminder gating.
- No change to the overlay or dashboard shape (owned by `redesign-todoist-overlay`).
- No removal of the `history_browsers` / `frontmost_app_name` config keys (left tolerated, just unused).

## Decisions

### D1 — Remove the two viewing branches from `update()`
`update(active_app, now)` keeps its signature (the caller in `work_guard.py` still passes `active_app`), but the body drops both the frontmost-app branch and the browser-history branch. After this, `active_app` is unused inside the method. Keep the parameter (caller compatibility, future re-use) and silence the unused-arg lint with a leading underscore reference or a short comment — do not change the call site.

### D2 — Remove `BrowserHistoryReader` from the monitor entirely
Delete the `self._reader` construction in `__init__`, the `self._reader.update_browsers(...)` line in `update_config`, and the `BrowserHistoryReader` import. The monitor no longer touches the browser-history code path.

### D3 — `BrowserHistoryReader` becomes dead code → delete it
With the monitor as its only consumer, `BrowserHistoryReader` and its Chromium history DB path constants in `todoist_signals.py` are dead. Remove the class and the path constants. `TodoistApiClient` and `_parse_iso` / helpers stay. (Alternative: leave it in place as unused — rejected; it is the only remaining local-file scanner and removing it is the privacy point of this change.)

### D4 — Token is the engagement gate
`api_enabled()` already returns `bool(self._token)`. After this change, when `api_enabled()` is false, `update()` does no engagement work at all (no other signal remains). `is_enabled()` (feature flag) still controls whether the monitor runs; the reminder still fires on the threshold when enabled, because absence of any observed interaction reads as non-interaction. No new code needed — this falls out of removing the two branches.

### D5 — Config keys left inert, not migrated
`history_browsers` and `frontmost_app_name` stay accepted in `config.json` but are no longer read. No migration, no validation error, no deprecation removal in this change — keeps the diff minimal and forward-safe. They simply have no effect.

## Risks / Trade-offs

- **User who relied on app/browser viewing to silence reminders** now gets reminders until they actually change a task → this is the intended behavior change; called out in the spec REMOVED migration note.
- **No token ⇒ feature is effectively just a threshold timer with an empty dashboard** → acceptable; documented in the modified "opt-in" requirement. The feature is opt-in and token-gated by design.
- **Coordination with `redesign-todoist-overlay`** (also edits `engagement_monitor.py` and `todoist_signals.py`) → the two diffs are disjoint: this change deletes signal sources in `update()` / `__init__` / the reader class; the other reshapes `dashboard()` and the persisted snapshot. Land order does not matter; if both are open, merge carefully around `__init__` and the imports.

## Migration Plan

1. Edit `engagement_monitor.py`: remove the two branches in `update()`, the reader construction and refresh, and the import.
2. Edit `todoist_signals.py`: remove `BrowserHistoryReader` and the Chromium DB path constants.
3. Update module docstrings in both files to describe a single API signal.
4. Rebuild via `bash rebuild.sh`; verify with a token: completing a task advances `last_engagement`; opening the Todoist app or visiting todoist.com does not.
Rollback: revert both files together; no persisted-state or config migration to undo.

## Open Questions

- Should the unused `active_app` parameter be dropped from `update()` and its call site too? Deferred — kept for caller-signature stability and possible future activity gating; revisit if it stays dead.
- Should `history_browsers` / `frontmost_app_name` be removed from any sample config / docs? Out of scope here; a docs sweep can follow.

## Why

Today Todoist engagement is the maximum of three local signals: frontmost `Todoist` app, Chromium browser-history visits to `todoist.com`, and Todoist REST API task changes. The user has decided engagement should mean *acting on tasks*, not *looking at Todoist*. The two viewing signals (frontmost app, browser history) reset the non-interaction timer whenever the user merely glances at Todoist without doing anything, which defeats the reminder. They also require local scanning the user no longer wants: polling the frontmost application name and reading the Chromium history SQLite database.

Restricting engagement to the API signal makes the timer reflect real task work, removes two privacy-sensitive local collectors, and simplifies the monitor to a single source of truth.

## What Changes

- **Engagement is derived from the Todoist REST API only.** The frontmost-app signal and the Chromium browser-history signal are removed as engagement sources. `last_engagement` is advanced solely by user-visible API task changes (complete / add / delete / move / reorder, plus cold-start active-task recency), with System Todoist Changes still excluded.
- **The browser-history collector is removed** — `BrowserHistoryReader` is no longer constructed or read by the monitor; WorkGuard no longer opens any Chromium history database. The frontmost-app name is no longer consulted for engagement.
- **The API token becomes required for any engagement detection.** Without `TODOIST_API_TOKEN` the feature has no engagement signal at all: the reminder still fires on the threshold (no interaction can be observed), but nothing can advance the timer. The token stays out of `config.json` (env / `.env` only), unchanged.
- **Config keys `history_browsers` and `frontmost_app_name` become inert** — read paths removed; the monitor ignores them. No config migration required.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `todoist-engagement-reminder`: the "Engagement is derived from three signal families" requirement collapses to a single API-derived source; the app-frontmost and browser-visit scenarios are removed. The "Feature is opt-in" requirement changes — without a token there is no engagement tracking (the previous app/browser fallback is gone). The Purpose and the "Unavailable signals" requirement update to one signal family.

## Impact

- `engagement_monitor.py` — drop the frontmost-app branch and the browser-history branch from `update()`; remove `BrowserHistoryReader` construction (`__init__`), its refresh in `update_config()`, and the import. `active_app` parameter retained in signature (caller compatibility) but no longer used for engagement.
- `todoist_signals.py` — `BrowserHistoryReader` becomes dead code; remove it and its Chromium DB path constants. `TodoistApiClient` unchanged.
- `config.py` — `read_todoist_token` unchanged. `history_browsers` / `frontmost_app_name` no longer consumed (left tolerated in config, undocumented).
- No change to the overlay, the dashboard shape, the threshold/cadence logic, or the API request surface. Privacy boundary tightens (one fewer local reader). Coordinate with the in-progress `redesign-todoist-overlay` change, which also touches `engagement_monitor.py` (snapshot shape) and `todoist_signals.py` (`dashboard()`) — the two edits are disjoint (this one removes signal sources; that one reshapes dashboard data).

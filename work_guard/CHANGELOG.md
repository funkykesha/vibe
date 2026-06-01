# Changelog

All notable changes to WorkGuard are recorded here. Newest first.

## Unreleased

### Changed

- **Pause removed, replaced by the overtime deferral ladder.** The menu no longer
  has a pause/resume toggle. During overtime a single contextual control offers
  `Отложить на 20 → 10 → 5 мин`, then `пора отдыхать`; outside overtime it shows
  `Работаем!` (disabled). A per-step unlock delay prevents rapid re-clicks.
- **Config schema migrated.** Flat schedule fields are lifted into
  `current_period_settings`, with new `pending_period_settings` and `deferral`
  objects. Legacy fields (`pause_until`, `work_apps`, `notification_interval_min`,
  `overlay_delay_min`, `overlay_lock_initial_sec`, `overlay_lock_max_sec`) are
  dropped on first launch. A one-time backup is written to
  `~/.config/work_guard/config.json.pre-deferral.bak` before migration — no manual
  action needed when upgrading from a pause-aware build.
- **Activity detection rewritten.** The `work_apps` whitelist is gone; activity is
  now any of recent keyboard/mouse input or lid-open with a focused user-facing app.

### Migration note

Upgrading from a pause-aware build: run `bash rebuild.sh`. The config migrates
automatically on first launch (backup written). Settings now expose only
`work_start`, `work_end`, `work_days`; schedule edits made during an active
overtime period apply at the next work-period boundary.

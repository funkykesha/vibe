# Progress

## 2026-05-12

- Hardened `install-workguard-applications-launchagent` intent before implementation: LaunchAgent `ProgramArguments` now use absolute `/usr/bin/open` plus `/Applications/WorkGuard.app`; packaging directory ambiguity is closed as `packaging/`.
- Implemented, verified, synced, and archived OpenSpec change `install-workguard-applications-launchagent`.
- Added main specs for `workguard-applications-rebuild`, `workguard-login-autostart`, `workguard-local-debug-launch`, `workguard-privacy-boundary`, and `workguard-activity-boundary`.
- Live `bash rebuild.sh` verification passed; post-rebuild manual checks passed for disk state, LaunchAgent state, runtime startup, single-instance app/debug launches, obsolete `setup.sh`, and no outbound telemetry patterns.

## 2026-05-11

- Clarified documentation roles: `AGENTS.md` is agent entrypoint, `CLAUDE.md` is redirect-only, `README.md` is the human-facing current workflow, `CONTEXT.md` is glossary/domain context, `.memory-bank/` is operational agent memory, and `docs/architecture/README.md` is the C4 status index.
- Reconciled supported launch contract across docs: public entrypoint is `bash rebuild.sh`; runnable app target is `/Applications/WorkGuard.app`; project-local `.app` is not a supported launch target; legacy setup flow is obsolete and appears only in history/archive context.
- Updated memory-bank operational notes to remove stale current guidance about direct-Python LaunchAgent flow and setup-era project-local app launch.
- Implemented and completed OpenSpec change `improve-status-calendar-overlay`.
- Added `production_calendar.py` with xmlcalendar.ru fetch/cache and day marker parsing (`+`, `*`, regular non-working markers).
- Updated `monitor.py` work-time logic for production calendar and shortened workday end (`work_end - 1 hour`).
- Updated `work_guard.py` for fast status refresh (~5s), elapsed-time overtime accounting, and overlay lock escalation with cap (`overlay_lock_initial_sec`/`overlay_lock_max_sec`).
- Updated `settings_dialog.py` with new lock settings and adaptive sizing/minsize to keep action buttons visible.
- Added `tests/manual/verify_production_calendar.py` and passed local verification.
- Updated README and architecture docs to reflect production calendar and elapsed-time behavior.
- Synced delta specs into `openspec/specs/` and archived change to `openspec/changes/archive/2026-05-11-improve-status-calendar-overlay`.
- Fixed recursive WorkGuard auto-start by disabling/removing legacy launchd agents (`com.agaibadulin.WorkGuard`, `com.workguard`) and hardening `scripts/stop_workguard.sh` to discover and disable WorkGuard-like LaunchAgents.

- Updated C4 architecture docs in `docs/architecture/`.
- Added `docs/architecture/c4-dynamic-launchagent-install.md` for the planned `install-workguard-applications-launchagent` flow.
- Clarified that `xmlcalendar.ru` is a network dependency and that LaunchAgent is planned deployment/install behavior, not a separate runtime container.
- Reconciled architecture docs with the new `install-workguard-applications-launchagent/proposal.md`: LaunchAgent opens `/Applications/WorkGuard.app`; it does not directly exec Conda Python.
- Added `.memory-bank/systemPatterns.md` to persist the current runtime, install, LaunchAgent, and external-boundary architecture patterns.
- Implementation not started yet; next step is applying the tasks.

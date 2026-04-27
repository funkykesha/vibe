# Product Context

## Problem
Developer starts Mac → needs Redis, Postgres, backend server etc. running. Easy to forget. No native lightweight monitor exists that's both menu bar + CLI-friendly.

## Solution
Menu bar "traffic light" shows all-green or problem. Full power through CLI in any terminal. Config is plain JSON.

## User Scenarios
1. **Morning startup** — daemon auto-started by LaunchAgent, checks services. Menu bar shows ❌. Click → Open CLI → see what's down → `startwatch restart all`.
2. **Quick check** — `startwatch status` in terminal. Exit code = number of failed services (scriptable).
3. **One-off start** — `startwatch start redis`.
4. **Add new service** — `startwatch config` → edit JSON → daemon picks up on next check.
5. **Diagnose tool itself** — `startwatch doctor`.

## CLI UX Principles
- Colored output by default, `--no-color` for pipes/CI
- `--json` flag on status for scripting
- Exit code = failed service count (0 = all OK)
- Fuzzy service name matching in `start`/`restart`
- `startwatch` with no args = `startwatch status`

## Supportability Issues (from v1.0 UX testing)
- No README — user didn't know what to do after install ← **in progress**
- Build warnings in `install.sh` output look like errors ← **in progress**
- Daemon not auto-started after `bash install.sh` (needs kickstart) ← **in progress**
- `startwatch config` opens nano — needs to know $EDITOR or set it

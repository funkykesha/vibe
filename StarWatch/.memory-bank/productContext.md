# Product Context

## Problem
Developer starts Mac → needs Redis, Postgres, backend server etc. running. Easy to forget. No native lightweight monitor exists that's both menu bar + CLI-friendly.

## Solution
Menu bar "traffic light" shows all-green or problem. Full power through CLI in any terminal. Config is plain JSON.

## User Scenarios
1. **Morning startup** — daemon auto-started by LaunchAgent, checks services. Menu bar shows ❌. Click → see which service is down → click "Запустить" → status updates in ~5s.
2. **Quick check** — `startwatch status` in terminal. Exit code = number of failed services (scriptable).
3. **One-off start/stop** — click service in menu bar → submenu → Запустить/Остановить/Перезапустить. No terminal needed.
4. **Edit config** — click "Open Config…" → popup NSPanel with JSON editor → Save validates JSON, writes file.
5. **Diagnose tool itself** — `startwatch doctor`.

## CLI UX Principles (unchanged)
- Colored output by default, `--no-color` for pipes/CI
- `--json` flag on status for scripting
- Exit code = failed service count (0 = all OK)
- Fuzzy service name matching in `start`/`restart`
- `startwatch` with no args = `startwatch status`

## UI UX (v2.0)
- Menu bar icon: ✅ (all running) / ⚠️ (any down)
- Per-service submenu: Запустить (disabled when running) / Остановить (disabled when stopped) / Перезапустить
- Config editor: floating NSPanel, monospace font, Save validates JSON before write, Cancel discards
- No terminal required for daily use

## Supportability Issues
- No README — user didn't know what to do after install ← **backlog**
- `representedObject` tuple unsafe ObjC bridging ← **backlog (fix with struct)**

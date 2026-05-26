# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> Keep `CLAUDE.md` and `AGENTS.md` identical — only the H1 and the line above differ.

## Execution Granularity

For multi-step tasks:

- make one compact plan;
- execute related operations in batches;
- run one verification bundle at the end;
- do not report after every trivial command;
- stop and hand off instead of continuing in a very large context.

## Session Start

1. `bd prime` — load beads workflow.
2. `.memory-bank/active-context/current-status.md` — operational status.
3. `.memory-bank/progress.md` — recent changes.
4. `README.md` — current human-facing workflow.
5. `CONTEXT.md` — glossary/domain context. Not agent instructions. Not runbook.
6. `docs/architecture/README.md` — C4 index with `Current` / `Planned` / `Archive` labels.

## Source Of Truth Map

- **Agent workflow / session rules:** `AGENTS.md`
- **Task tracking:** `bd` / beads. Do not use markdown TODO instead of beads.
- **Current public run/install contract:** `README.md`
- **Domain glossary and terminology:** `CONTEXT.md`
- **Architecture views and intent boundaries:** `docs/architecture/`
- **Operational memory for agents:** `.memory-bank/`
- **Historical decisions and reviews:** `.memory-bank/project-context/review-history/`
- **OpenSpec intent:** `openspec/changes/*`, `openspec/specs/*`

## Commands

**Rebuild and install:**
```bash
bash rebuild.sh
```
Rebuilds the app bundle, copies to `/Applications/WorkGuard.app`, re-signs (ad-hoc), reloads LaunchAgent, relaunches. Only supported install entrypoint. `setup.sh` is obsolete — it errors and redirects here.

**Stop WorkGuard:**
```bash
bash scripts/stop_workguard.sh
```

**Debug launch (direct Python, not a supported install target):**
```bash
conda run -n work_guard python work_guard.py
```

**Settings dialog standalone:**
```bash
conda run -n work_guard python settings_dialog.py
```

## Architecture

WorkGuard is a macOS menu bar app: Python core + optional Swift menu agent.

### Containers

| Container | Tech | Role |
|-----------|------|------|
| **Python core** | Python 3.11, `rumps`, PyObjC, `pynput` | NSApplication loop, monitoring tick (~5s), overtime accounting, escalation, writes `status.json` |
| **Swift menu agent** | Swift, Cocoa | Optional `NSStatusItem`; reads `status.json`, writes `command.json`; enabled by `WORKGUARD_SWIFT_MENU` and binary presence |
| **Overlay child process** | Python, PyObjC | Separate process for NSApplication main-thread compliance; full-screen blocking overlay |
| **Settings subprocess** | Python, tkinter | Separate process to avoid Tk/AppKit threading conflicts |
| **Local store** | JSON files | `~/.config/work_guard/` — see below |

### Module Map

| Module | File |
|--------|------|
| App entry, menu, Swift IPC, monitoring loop | `work_guard.py` (`WorkGuardApp`, `_monitoring_loop`) |
| Activity monitoring | `monitor.py` (`ActivityMonitor`, `KeyboardWatcher`, `LidWatcher`) |
| Production calendar | `production_calendar.py` (fetches xmlcalendar.ru, caches locally) |
| Overtime notifications | `notifier.py` |
| Full-screen overlay | `overlay.py` (also `__main__` for subprocess launch) |
| Config load/save | `config.py` |
| ASCII art by escalation level | `ascii_art.py` |
| Settings UI | `settings_dialog.py` (also `__main__`) |
| Swift menu agent | `WorkGuardMenu/main.swift` |
| App bundle template | `packaging/WorkGuard.app` |

### Data Files (`~/.config/work_guard/`)

- `config.json` — schedule, work_apps list, pause_until, overlay locks
- `status.json` / `command.json` — Python ↔ Swift IPC
- `work_guard.lock` — single-instance PID lock
- `work_guard.log` — runtime log
- `calendar_ru_<year>.json` — cached production calendar

## Product Contract

- Single public entrypoint: `bash rebuild.sh`.
- Single supported GUI target: `/Applications/WorkGuard.app`.
- Project-local `.app` is not a supported launch target — it is a template in `packaging/`.
- `setup.sh` is obsolete — not a wrapper, not a fallback.
- LaunchAgent: `~/Library/LaunchAgents/com.agaibadulin.workguard.plist`; runs `/usr/bin/open /Applications/WorkGuard.app`, `RunAtLoad=true`, `KeepAlive=false`.
- Bundle ID `com.agaibadulin.workguard` is stable across rebuilds — never change it to force cache refresh.
- Direct Python launch = debug/diagnostics only.
- ActivitySignals = future boundary only; local/coarse-only; no collectors yet.
- Nothing leaves the machine without explicit user request; secrets never leave under any path.

## OpenSpec and Beads

Enable OpenSpec workflow only when `openspec/` and `.beads/` exist or user explicitly requests OpenSpec.

Order:
1. OpenSpec captures intent.
2. Beads captures task graph and execution state.
3. Code and docs are aligned with intent.

Rules:
- Don't start implementation before clear intent.
- Keep OpenSpec, Beads, code/docs in sync.
- If `openspec/AGENTS.md` exists, it is authoritative for schema and commands inside `openspec/`.
- Don't overwrite others' changes without explicit request.

## Beads

Run `bd prime` at session start.

```bash
bd ready
bd show <id>
bd update <id> --claim
bd close <id>
bd dolt push
```

## Non-Interactive Shell

Always use non-interactive flags for file commands:

```bash
cp -f source dest
mv -f source dest
rm -f file
rm -rf directory
cp -rf source dest
```

Also:
- `scp -o BatchMode=yes`
- `ssh -o BatchMode=yes`
- `HOMEBREW_NO_AUTO_UPDATE=1 brew ...`

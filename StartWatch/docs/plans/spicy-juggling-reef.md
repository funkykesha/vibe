# Plan: opsx:propose backlog-stability-fixes

## Context

Creating openspec change `backlog-stability-fixes` with proposal, design, and tasks artifacts. Bugs have already been analyzed and decisions made. Goal is to verify the design matches intent before implementation.

## What I'll create

`openspec new change "backlog-stability-fixes"` → write 3 artifacts.

---

## Artifact: proposal.md

**Why:** 5 active bugs and 1 feature gap degrading UX — CLI hangs, wrong service count in menu, no `list`/`stop` commands, old processes not killed on restart, daemon hangs in debug build.

**Scope (5 bugs + menu icons, 2 skipped):**
- Bug #1: restart hangs terminal (ServiceRunner.run calls waitUntilExit)
- Bug #2: menu bar shows wrong service count (cache not aligned with config)
- Bug #4: CLI missing `list` and `stop`, help lacks examples
- Bug #6: restart doesn't kill old processes (no stop before start)
- Bug #7: daemon hangs if .app missing (no existence check)
- Menu icons: 4 states (running/starting/partial/all-failed)
- Bug #3 (icon disappears): skip — covered by other fixes
- Bug #5 (notification on log): skip

---

## Artifact: design.md

### Bug #1 — Hang при restart all

**Root cause:** `ServiceRunner.run()` calls `process.waitUntilExit()`. Long-running services never exit → terminal hangs.

**Fix:**
- New `ServiceRunner.runBackground(command:cwd:)` — spawn without waitUntilExit
- `ServiceConfig` gets `startupTimeout: Int?` field (default 10s)
- RestartCommand rewrites to:
  1. Write `isStarting: true` to last_check.json for each service being restarted
  2. Spawn all services via runBackground()
  3. Poll each via `ServiceChecker.check()` every 500ms up to startupTimeout
  4. Live table in terminal: ANSI in-place update for "starting" rows with elapsed timer
  5. Exit with code = count of still-failed services

**Files:** `ServiceRunner.swift`, `RestartCommand.swift`, `Config.swift`, `CheckResult.swift`

---

### Bug #2 — Menu wrong service count

**Root cause:** `IPCClient.getLastResults()` filters cache to only include services present in both config AND cache. Services added since last check are silently dropped.

**Fix:**
- `IPCClient.getLastResults()` → return ALL services from config
- For each: use cache entry if present, otherwise synthesize `CheckResult(isRunning: false, detail: "unknown")`
- `CodableCheckResult` gets `isStarting: Bool?` field (nil = not starting, true = actively being started)

**Files:** `IPCClient.swift`, `CheckResult.swift`

---

### Bug #4 — CLI неочевиден

**Fixes:**
- Add `ListCommand`: reads config, prints service names + check type/value
- Add `StopCommand`: sends `.quit` IPC message (stops daemon + menu agent)
- CLIRouter: add `list` and `stop` cases
- `printHelp()`: add examples section with common workflows

**Files:** `CLIRouter.swift`, new `ListCommand.swift`, new `StopCommand.swift`

---

### Bug #6 — Старые процессы не убиваются

**Root cause:** RestartCommand calls `ServiceRunner.run()` directly — starts new process without killing old one.

**Fix:** Before spawning, kill existing process by check type:
- `http` check: extract port from URL → `lsof -ti tcp:<port> | xargs kill -9`
- `port` check: `lsof -ti tcp:<value> | xargs kill -9`
- `process` check: `pkill -f <value>`
- `command` check: no-op

Extract this logic as `ServiceRunner.killExisting(service:)` (mirrors ProcessManager.killExternal).

**Files:** `ServiceRunner.swift`, `RestartCommand.swift`

---

### Bug #7 — Daemon висит при debug build

**Root cause:** `spawnMenuAgentIfNeeded()` calls `/usr/bin/open -na /Applications/StartWatchMenu.app` without checking existence first. If .app missing, open may block or error.

**Fix:**
- Check `FileManager.default.fileExists(atPath: appPath)` before calling open; return silently if not found
- Add `--no-menu` flag to DaemonCommand; if set, skip all menu agent spawning

**Files:** `AppDelegate.swift`, `DaemonCommand.swift`

---

### Menu bar — 4 icon states

**New states** (replacing binary ♻️/⚠️):
- ♻️ all running
- ⏳ at least one has `isStarting: true` in cache
- ⚠️ some running, some failed
- ❌ all failed

**Polling intervals:**
- Any service starting → 0.5s poll
- Otherwise → 3s poll
- MenuBarController manages timer, switches rate based on state

**Data flow:** RestartCommand writes `isStarting: true` for services it spawns → cache → menu agent reads on next poll → shows ⏳

**Files:** `MenuBarController.swift`, `CheckResult.swift`, `IPCClient.swift`

---

## Artifact: tasks.md

Tasks will be broken down by bug, each with: code change + verify step.

Rough shape:
1. Config.swift: add `startupTimeout: Int?` to ServiceConfig, `isStarting: Bool?` to CodableCheckResult
2. ServiceRunner.swift: add `runBackground()`, add `killExisting(service:)`
3. RestartCommand.swift: rewrite with background spawn + polling + live table
4. IPCClient.swift: fix getLastResults() to include all config services
5. MenuBarController.swift: 4-state icon + adaptive polling timer
6. ListCommand.swift: new file
7. StopCommand.swift: new file
8. CLIRouter.swift: add list/stop routes, update help
9. AppDelegate.swift: add .app existence check, support --no-menu
10. DaemonCommand.swift: add --no-menu flag
11. swift build — no errors
12. swift test — all pass

---

## Files to create

```
openspec/changes/backlog-stability-fixes/
  .openspec.yaml
  proposal.md
  design.md
  tasks.md
```

## Verification

After implementation:
- `swift build` — zero errors
- `swift test` — all pass
- Manual: `startwatch restart all` — shows live table, exits after timeout, no hang
- Manual: `startwatch list` — shows services from config
- Manual: `startwatch stop` — stops daemon
- Manual: add service to config, check menu shows unknown → updates after check

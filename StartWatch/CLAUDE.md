# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

```bash
swift build                          # debug build
swift build -c release               # release build
swift test                           # all tests
swift test --filter CheckSchedulerTests/testMethodName  # single test
```

Run the binary directly (debug):
```bash
.build/debug/StartWatch status
.build/debug/StartWatch check
```

**Do not run `install.sh`** — requires sudo, installs to `/usr/local/bin` and registers LaunchAgent.

## Architecture

Single binary, three execution modes dispatched in `main.swift`:
- `daemon` → `DaemonCommand` — background process, runs `CheckScheduler`, serves `IPCServer`
- `menu-agent` → `MenuAgentCommand` — macOS menu bar NSApp, reads daemon state via IPC
- CLI commands → `CLIRouter` → individual `*Command` structs (status, check, start, restart, config, log, doctor, etc.)

**IPC**: daemon binds a Unix socket; CLI and menu-agent connect via `IPCClient`. Messages typed via `IPCMessage`. CLI reads daemon's last-check cache (4-hour TTL); `startwatch check` forces live re-check.

**Config**: `~/.config/startwatch/config.json`. Watched by `FileWatcher` (FSEvents + 200 ms debounce); daemon reloads on change.

**Check types** (`CheckResult`): `port` (TCP connect), `http` (GET → 2xx/3xx), `process` (`pgrep -f`), `command` (exit 0).

**Terminal launch** (`TerminalLauncher`): selects adapter via `TerminalProtocol` — one concrete type per terminal (Warp, iTerm, Apple Terminal, Alacritty, Kitty).

**Source layout:**
```
Sources/StartWatch/
  CLI/Commands/       — one file per CLI command
  CLI/Formatting/     — ANSIColors, ReportBuilder, TableFormatter
  Core/               — CheckResult, AsyncHelpers, …
  IPC/                — IPCServer, IPCClient, IPCMessage
  MenuAgent/          — NSApp menu bar UI
  Terminal/           — TerminalLauncher + per-terminal adapters
  Notifications/      — NotificationManager
```

`startwatch status` exit code = number of failed services (0 = all OK; scriptable in CI/shell prompts).

---

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

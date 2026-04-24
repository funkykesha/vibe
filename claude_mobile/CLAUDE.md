# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Monorepo Structure

`claude_mobile` is a monorepo containing three independent projects. Each has its own CLAUDE.md with detailed architecture and build instructions.

| Project | Type | CLAUDE.md | Purpose |
|---------|------|-----------|---------|
| **work_guard** | Swift (macOS) | [CLAUDE.md](work_guard/CLAUDE.md) | Menu-bar app monitoring work hours, escalates notifications/overlays when working outside schedule |
| **finance-dashboard** | React/HTML | [CLAUDE.md](finance-dashboard/CLAUDE.md) | Single-file personal finance dashboard: salary distribution & capital tracking in RUB/USD |
| **motodocs** | Static HTML | — | Documentation (minimal; single index.html) |

## How to Work With This Repo

1. **Navigate to the project folder** you're working on (e.g., `cd work_guard`)
2. **Read its CLAUDE.md** for build, architecture, and conventions specific to that project
3. **All git history is shared**; commits at the root level apply to whichever subproject(s) changed

## Repository Clarity

**Note:** There is a duplicate/stale folder at `/vibe/work_guard/` (outside this repo). Ignore it; the canonical work_guard is in `claude_mobile/work_guard/` with active git history.

## Common Commands

```bash
# View git log across all projects
git log --oneline

# Check status
git status

# Commit changes (affects only changed subproject files)
git add <subproject files>
git commit -m "message"
```

## Tech Stack by Project

- **work_guard**: Swift, Cocoa framework, NSStatusItem, CGEvent, UNUserNotificationCenter
- **finance-dashboard**: React 18, Babel JSX, Tailwind CSS, localStorage
- **motodocs**: Static HTML

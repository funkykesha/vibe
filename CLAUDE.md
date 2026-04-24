# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Workspace Overview

`vibe` is a workspace containing multiple independent projects. Each project has its own git repository and detailed guidance file.

## Projects

### 1. **groovy_agent** — AI-powered JSON transformation tool

**Type:** Node.js + Express + Browser  
**Purpose:** Write and execute Groovy scripts for JSON transformation using AI assistance  
**Repository:** `https://github.com/agaibadulin/groovy_agent.git`  
**Guidance:** [groovy_agent/CLAUDE.md](groovy_agent/CLAUDE.md) and [groovy_agent/ARCHITECTURE.md](groovy_agent/ARCHITECTURE.md)

**Key Components:**
- Express backend with model management, proxy to Yandex Eliza API
- Single-page HTML/CSS/JS frontend with CodeMirror editors
- Groovy subprocess execution with real-time output
- Knowledge base system and user-defined rules

**Stack:** Node.js 18+ (Express), Groovy, OpenAI/Anthropic/Yandex APIs

**Quick Start:**
```bash
cd groovy_agent
npm install
npm run dev   # Start with watch hot-reload
```

**Prerequisites:** Groovy installed (`brew install groovy`), `.env` with `ELIZA_TOKEN`

---

### 2. **claude_mobile** — Monorepo of three independent projects

**Type:** Mixed (Swift, React, Static HTML)  
**Repository:** `git@github.com:funkykesha/claude_mobile.git`  
**Guidance:** [claude_mobile/CLAUDE.md](claude_mobile/CLAUDE.md)

This is a monorepo containing three separate applications. Navigate to each subproject and read its individual CLAUDE.md for detailed instructions.

#### **work_guard** — Work schedule monitoring app
- **Type:** Swift (macOS menu-bar app)
- **Purpose:** Monitor work hours, escalate notifications/overlays when working outside schedule
- **Stack:** Swift, Cocoa framework, NSStatusItem, CGEvent, UNUserNotificationCenter
- **Guidance:** [claude_mobile/work_guard/CLAUDE.md](claude_mobile/work_guard/CLAUDE.md)

#### **finance-dashboard** — Personal finance tracker
- **Type:** React single-file app
- **Purpose:** Track salary distribution and capital in RUB/USD
- **Stack:** React 18, Babel JSX, Tailwind CSS, localStorage
- **Guidance:** [claude_mobile/finance-dashboard/CLAUDE.md](claude_mobile/finance-dashboard/CLAUDE.md)

#### **motodocs** — Static documentation
- **Type:** Static HTML
- **Purpose:** Technical documentation
- **Guidance:** Minimal; single `index.html` file

---

### 3. **moto_docs** — Documentation project

Standalone documentation folder. Check `concept.md` for content.

---

## How to Work With This Workspace

1. **Identify which project needs work** (groovy_agent, work_guard, finance-dashboard, etc.)
2. **Navigate to that project folder:**
   ```bash
   cd <project-name>
   ```
3. **Read its CLAUDE.md** for architecture, build commands, and conventions specific to that project
4. **Work within that directory** — each project has its own git history and dependencies

## Repository Clarity

**Note:** There is a duplicate/stale folder at `/vibe/work_guard/` (outside claude_mobile). Ignore it; the canonical work_guard is in `claude_mobile/work_guard/` with active git history.

## Git Workflow

Each project is a separate git repository:

```bash
# groovy_agent changes
cd groovy_agent
git add <files>
git commit -m "message"
git push

# claude_mobile changes
cd claude_mobile
git add <files>
git commit -m "message"
git push
```

Root-level workspace changes (if any) stay local in `/vibe/`.

## Technology Summary

| Project | Language | Framework | Key Features |
|---------|----------|-----------|--------------|
| groovy_agent | JavaScript | Express | LLM proxy, Groovy execution, SSE streaming |
| work_guard | Swift | Cocoa | Menu-bar app, event monitoring, notifications |
| finance-dashboard | JavaScript | React 18 | Single-file app, localStorage, Tailwind |
| motodocs | HTML | Static | Documentation |

## Common Tasks

**See what projects have uncommitted changes:**
```bash
cd groovy_agent && git status
cd ../claude_mobile && git status
```

**View recent commits across projects:**
```bash
cd groovy_agent && git log --oneline -5
cd ../claude_mobile && git log --oneline -5
```

**Install dependencies (project-specific):**
```bash
cd groovy_agent && npm install  # Node.js project
cd ../claude_mobile/finance-dashboard && npm install  # React project
```

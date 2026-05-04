# System Patterns

## Architecture Overview
Single-page React 18 app rendered from `index.html` with Babel-in-browser JSX. Salary and capital logic live in one runtime script, while backend endpoints handle persistence for accounts, settings, salary events, and snapshots.
Implementation is now managed as stage-owned OpenSpec changes plus a named Codex subagent roster instead of one broad finance roadmap.

## Tech Stack

| Layer | Technology | Version | Rationale |
|-------|-----------|---------|-----------|
| UI | React | 18 UMD CDN | No build step |
| JSX | Babel standalone | CDN | Runtime transpilation |
| Styling | Tailwind CSS | CDN | Fast utility styling |
| Persistence | localStorage + FastAPI backend | current repo | Salary UI still uses `fin-v3` import/export while persisted records live in backend APIs |
| Backend | FastAPI, SQLAlchemy, Pydantic | current repo | Lightweight API for settings/accounts/salary-events/snapshots |
| Planning | OpenSpec | current repo | Completed and remaining work tracked as stage-owned changes |
| Agent orchestration | Codex custom agents | local `~/.codex` | Per-role model selection for implementation and verification |

## Key Design Patterns

### Single-file runtime
- **Where**: `index.html`
- **Why**: Keeps the frontend easy to inspect and edit without a build tool.

### Backend-served frontend shell
- **Where**: `backend/app/main.py`
- **Why**: `uvicorn backend.app.main:app` serves both `/api/*` and the root dashboard HTML via `FileResponse(index.html)`.

### Derived state for calculations
- **Where**: salary distribution logic
- **Why**: Inputs are persisted separately from derived totals like `net`, `totalDeds`, and distribution rows.

### Local-first persistence with backend sync
- **Where**: salary UI state in `fin-v3`, backend for settings/accounts
- **Why**: Allows fast UI edits while preserving data across reloads and sessions.

### Stage-owned implementation flow
- **Where**: `openspec/changes/` and archived `openspec/specs/*`
- **Why**: Completed work (`dashboard-ritual-ux`, `backend-foundation`, `dashboard-api-migration`, `salary-events-snapshots`) and remaining work (`telegram-finance-assistant`, `tbank-account-sync`, `deployment-readiness`) are separated by explicit handoff criteria.

### Role-specific Codex subagents
- **Where**: `~/.codex/agents/*.toml`
- **Why**: Product guard, UX worker, backend worker, migration worker, domain worker, and verifiers use different model/reasoning budgets instead of one generic agent profile.

## Directory Structure
- `index.html` - entire runtime UI and client logic.
- `backend/app/` - FastAPI app, schemas, models, seed data.
- `openspec/changes/` - change proposals, specs, design, tasks.
- `.memory-bank/` - persistent project context for Codex.

## Error Handling Strategy
- Use loose parsing for user-entered numeric fields.
- Fail silently on localStorage writes.
- Show startup and save-state errors in the UI for backend operations.
- Keep stage handoffs explicit before starting Telegram/provider/deployment work.

---
*Updated on architectural decisions or tech stack changes.*

# Active Context

> Updated most frequently - reflects current work state.

## Current Focus
The dashboard now runs as a FastAPI-served app with backend-backed accounts/settings, explicit salary events, explicit snapshots, and history comparison.
Current work has shifted from implementation to orchestration: the remaining finance stages were ordered, a visual roadmap was generated, and finance-specific Codex subagents were configured for the next implementation wave.

## Recent Changes

| Date | Change | Files |
|------|--------|-------|
| 2026-05-03 | Implemented and archived `dashboard-ritual-ux` | `index.html`, `openspec/specs/dashboard-ritual-ux/spec.md` |
| 2026-05-03 | Implemented and archived `backend-foundation` | `backend/app/*`, `.env.example`, `.gitignore`, `openspec/specs/backend-foundation/spec.md` |
| 2026-05-03 | Implemented and archived `dashboard-api-migration` | `index.html`, `openspec/specs/dashboard-api-migration/spec.md` |
| 2026-05-03 | Implemented and archived `salary-events-snapshots` | `backend/app/*`, `index.html`, `openspec/specs/salary-events-snapshots/spec.md` |
| 2026-05-03 | Reviewed remaining stage order and generated visual roadmap | `~/.agent/diagrams/finance-spec-implementation-order.html` |
| 2026-05-03 | Added finance-specific Codex subagent configs | `~/.codex/config.toml`, `~/.codex/agents/*.toml` |

## Active Decisions

### Decision 1
- **Context**: The frontend still has no build step.
- **Chosen**: Keep runtime in `index.html`.
- **Why**: Matches repo constraints and avoids introducing bundling/tooling.

### Decision 2
- **Context**: Dashboard now depends on backend APIs for persisted finance data.
- **Chosen**: Run via FastAPI root URL, not direct `file://` or raw `open index.html`.
- **Why**: Client fetches relative `/api/*` endpoints.

### Decision 3
- **Context**: Default `python3` is 3.14 and pinned Pydantic core failed to build there.
- **Chosen**: Use `python3.13` for local backend runtime.
- **Why**: Verified dependency install and FastAPI smoke checks passed on Python 3.13.

### Decision 4
- **Context**: Remaining stages need stable role ownership for Telegram, provider sync, and later verification work.
- **Chosen**: Configure named Codex subagents with per-role model/reasoning settings in `~/.codex/agents/`.
- **Why**: Keeps implementation cost and depth aligned with each role.

## Next Steps
- [ ] For local use: create `.venv` with `python3.13`, install `backend/requirements.txt`, run `uvicorn backend.app.main:app --reload --host 127.0.0.1 --port 8000`.
- [ ] Decide whether Python 3.14 compatibility matters enough to update dependency pins.
- [ ] Start the remaining active changes in order: `telegram-finance-assistant`, then `tbank-account-sync`, then `deployment-readiness`.
- [ ] Keep OpenSpec changes aligned with the completed four stages before starting Telegram/TBank/provider work.
- [ ] Re-read activeContext at the start of the next work session.

## Open Questions
- [ ] Should Python 3.13 remain the required local runtime, or should dependency pins be updated for Python 3.14?
- [ ] Whether the new Codex subagent TOML files are fully consumed by the current Codex build without extra naming or restart constraints.

---
*Updated at the start and end of each work session.*

# Progress

## What Works
- FastAPI serves the dashboard at `/` and APIs under `/api/*`.
- `dashboard-ritual-ux`, `backend-foundation`, `dashboard-api-migration`, and `salary-events-snapshots` are implemented, verified, archived, and committed.
- Dashboard starts on `Ритуалы`, supports theme modes, backend loading/error/save states, and explicit `fin-v3` import when backend is empty.
- Accounts/settings are backend-backed through `GET/PATCH /api/accounts` and `GET/PATCH /api/settings`.
- Salary events are saved only by explicit user action via `POST /api/salary-events`.
- Snapshots are created only by explicit user action via `POST /api/snapshots`.
- History renders app-created snapshots and can compare the two latest snapshots via `/api/snapshots/compare`.
- Remaining staged work is clearly ordered: Telegram -> TBank sync -> deployment, with OCR/photo deferred.
- Codex finance subagent roster is configured in `~/.codex/agents/` with per-role model and reasoning settings.

## In Progress
- No production implementation stage is currently active.
- Current session was a planning/orchestration pass plus memory-bank refresh.

## What is Left

### Must Have - P0
- [ ] Decide whether to keep Python 3.13 as required runtime or update dependency pins for Python 3.14.
- [ ] Keep generated `backend/data/app.db` out of commits.
- [ ] Preserve source-of-truth contract before Telegram/TBank integration.
- [ ] Implement `telegram-finance-assistant`.
- [ ] Implement `tbank-account-sync`.

### Should Have - P1
- [ ] Implement `deployment-readiness`.
- [ ] Add automated tests if backend behavior grows beyond current smoke checks.
- [ ] Verify the new Codex subagent files are picked up cleanly after app restart.
- [ ] Consider a clearer UI for comparing arbitrary snapshots, not only the two latest.

### Nice to Have - P2
- [ ] Keep `deferred-ocr-photo-flow` outside MVP while preserving its boundary docs.
- [ ] Add a short README run section for backend startup.

## Known Issues

| # | Description | Severity | Status |
|---|-------------|----------|--------|
| 1 | `python3` maps to 3.14 locally; pinned Pydantic core failed to build under 3.14 | Medium | Open |
| 2 | Worktree has unrelated pre-existing dirty files outside this completed run | Low | Open |

## Decisions Log

| Date | Decision | Alternatives | Rationale |
|------|----------|--------------|-----------|
| 2026-05-03 | Run app through FastAPI URL | Open `index.html` directly | API-backed frontend needs relative `/api/*` |
| 2026-05-03 | Use Python 3.13 for verified backend runtime | Use default Python 3.14 | Current dependency pins install cleanly on 3.13 |
| 2026-05-03 | Keep snapshots explicit | Auto-create on account edit | Product contract says history checkpoints must be user-requested |
| 2026-05-03 | Configure finance-specific Codex subagents | Use generic agents with ad hoc prompts | Better cost control and cleaner role ownership |

---
*Updated when tasks are completed or new issues are discovered.*

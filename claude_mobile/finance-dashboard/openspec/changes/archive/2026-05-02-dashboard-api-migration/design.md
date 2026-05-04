## Context

Archived spike found localStorage key `fin-v3` with `cats`, `deds`, `accs`, `usdRate`, and `mortgage`. Salary inputs are not persisted, so they cannot be migrated as history.

## Decisions

### D1: Backend read wins after migration

After successful migration, the dashboard reads accounts/settings from API. localStorage is only an initial import source or fallback warning source, not the source of truth.

### D2: Use partial writes

Settings and account updates SHALL write only changed fields where the API supports it. The dashboard SHALL NOT replace whole arrays with stale client copies after unrelated changes.

### D3: Treat loading and errors as first-class UI states

The dashboard SHALL communicate loading, failed fetch, failed save, and retry states without silently showing stale values as fresh.

### D4: Guard fetch races

The dashboard SHALL ignore stale responses or cancel obsolete requests when later requests supersede them.

### D5: Calculations remain stable

Migration changes data transport only. Salary and capital formulas, tolerant numeric parsing, and derived totals remain equivalent.

## Evidence

- Archived research `03-mini-spikes-and-context7.md` section 3.1: localStorage shape, no salary persistence, migration constraints.
- Archived research section 3.7: React effect cleanup and controlled state; MDN fetch requires checking `response.ok`; CORS only matters for split origins.

## Handoff

Entry criteria:
- `backend-foundation` exposes accounts/settings APIs and static serving.
- Current localStorage shape is still readable for optional import.

Exit criteria:
- Dashboard no longer treats localStorage as source of truth.
- API failures are visible and do not corrupt local edits.
- Salary/capital calculation verification matches pre-migration behavior.

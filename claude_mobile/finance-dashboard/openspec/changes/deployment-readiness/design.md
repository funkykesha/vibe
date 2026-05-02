## Context

Research recommends local-first SQLite for MVP development but managed Postgres for deployed persistence. Telegram webhook mode depends on a real HTTPS deployment target.

## Decisions

### D1: Managed Postgres is the deployed default

Deployment SHALL use managed Postgres or an equivalent persistent managed database. SQLite may remain local-only unless persistent disk and backup plan are explicitly approved.

### D2: Secrets come from platform environment

Secrets SHALL be provided by deployment environment variables, not committed files.

### D3: Backups are part of readiness

Deployment is not ready until backup and restore procedures exist for the financial database.

### D4: Webhook mode is deployment-specific

Telegram webhook mode SHALL use HTTPS URL, secret token, and explicit pending-update behavior. Polling remains local-first.

### D5: Access boundary must be deployed

Single-user deployment SHALL include a configured access boundary for dashboard/API/bot surfaces.

## Evidence

- Archived research `03-mini-spikes-and-context7.md` section 3.6: Railway/Render support Postgres and env variables; SQLite persistence requires volume/disk planning; Postgres is safer deployed default.
- Archived research section 3.5: Telegram webhook requires HTTPS URL, secret token, and pending-update behavior.
- Archived research section 3.2: Uvicorn reload/workers choices are process-mode dependent.

## Handoff

Entry criteria:
- Local backend/dashboard/bot flows are verified.
- Required secrets and runtime processes are known.

Exit criteria:
- Deployment target has managed database, secrets, access boundary, backup/restore, and webhook plan.
- Deployed app does not depend on ephemeral SQLite storage.
- Rollback and restore steps are documented.

## Why

The roadmap needs a small backend foundation before dashboard migration, salary events, snapshots, Telegram, or TBank sync can share state. The old automation change combined too many stages; this replacement owns only config, database foundation, accounts/settings API, static serving, CORS, seed, and access boundary.

## What Changes

- Add typed configuration with `.env.example`, `DATABASE_URL`, bot/deployment variables, and explicit secret handling.
- Add FastAPI application foundation with SQLAlchemy database access.
- Add idempotent seed for current account/settings defaults.
- Add accounts and settings APIs for current dashboard data.
- Serve the static dashboard and define local CORS behavior.
- Define trusted local/deployed access boundaries for the single-user app.

## Capabilities

### New Capabilities

- `backend-foundation`: Config, persistence foundation, accounts/settings APIs, seed, static serving, CORS, and single-user access boundary.

## Impact

- This stage creates backend infrastructure but does not migrate dashboard data access yet.
- Snapshot, salary event, provider mapping, Telegram, and deployment-specific behavior are owned by later replacement changes.

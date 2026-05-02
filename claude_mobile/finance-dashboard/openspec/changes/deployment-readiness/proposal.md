## Why

Deployment should happen only after local flows work, and it must not rely on ephemeral SQLite or unplanned public access. This change defines managed Postgres readiness, secrets, backups, process model, static serving, and Telegram webhook deployment.

## What Changes

- Define deployment target readiness for Railway or Render-style platforms.
- Require managed Postgres for deployed persistence.
- Define secret and environment variable handling.
- Define backup and restore expectations.
- Define webhook deployment for Telegram after local polling is proven.
- Reject ephemeral SQLite as deployed dependency.

## Capabilities

### New Capabilities

- `deployment-readiness`: Deployment storage, secrets, backups, process, and Telegram webhook readiness.

## Impact

- Depends on local backend, dashboard, bot, snapshot, and provider behavior being stable enough to deploy.
- Does not change MVP local-first development path.

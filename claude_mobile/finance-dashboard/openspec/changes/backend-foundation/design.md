## Context

The current dashboard persists `cats`, `deds`, `accs`, `usdRate`, and `mortgage` in localStorage. This stage introduces backend source-of-truth infrastructure for accounts/settings without changing production dashboard behavior yet.

## Decisions

### D1: Use typed settings

Configuration SHALL be centralized in a Pydantic Settings object. Modules SHALL NOT read `os.environ` directly.

### D2: Use sync SQLAlchemy for local single-user MVP

Sync SQLAlchemy and context-managed sessions are sufficient for this local-first, single-user foundation.

### D3: Seed is additive and idempotent

Seed imports current defaults only when records are missing. It SHALL NOT overwrite existing balances or settings on repeated runs.

### D4: Accounts and settings APIs stay narrow

The foundation exposes current accounts and settings. Snapshot, salary event, and provider mapping writes are excluded from this stage.

### D5: Local and deployed trust boundaries are explicit

Local serving may trust localhost. Deployed serving must not expose public unauthenticated financial APIs without a configured access boundary.

## Evidence

- Archived research `03-mini-spikes-and-context7.md` section 3.2: FastAPI static/sync endpoints, SQLAlchemy session patterns, Pydantic Settings, python-dotenv behavior, Uvicorn process choices.
- Archived research section 3.6: SQLite is fine locally; deployed reliability should not depend on ephemeral SQLite.
- Decision log D6: local-first does not remove deployed security requirements.

## Handoff

Entry criteria:
- Product contract is accepted.
- Config variables and current persisted dashboard shape are known.

Exit criteria:
- Accounts/settings API contracts exist and are verified locally.
- The dashboard can still run unchanged until `dashboard-api-migration`.
- Later changes can add snapshots, salary events, Telegram, and provider sync without redefining config or database foundation.

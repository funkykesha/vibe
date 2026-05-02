## 1. Configuration

- [x] 1.1 Add typed settings for `DATABASE_URL`, `ALLOWED_ORIGINS`, static serving, bot placeholders, and deployment-sensitive values.
- [x] 1.2 Add `.env.example` and ensure `.env` secrets are ignored.
- [x] 1.3 Document local defaults and required deployment overrides.

## 2. Database And Seed

- [x] 2.1 Add SQLAlchemy engine/session/base foundation.
- [x] 2.2 Add account and settings persistence for current dashboard state.
- [x] 2.3 Add idempotent seed from current default accounts/categories/deductions/settings.

## 3. API And Serving

- [x] 3.1 Add `GET /api/accounts` and narrow account update behavior.
- [x] 3.2 Add `GET /api/settings` and partial settings update behavior.
- [x] 3.3 Serve the static dashboard from FastAPI.
- [x] 3.4 Configure local CORS and deployed allowed origins.

## 4. Verification

Entry criteria:
- `finance-product-contract` defines shared-state concepts and single-user boundary.
- External backend/config evidence from archived research is available.

Exit criteria:
- Accounts/settings source of truth is available through API.
- Dashboard migration can start without adding snapshot, salary event, provider, or bot behavior to this stage.

- [x] 4.1 Verify backend starts with local defaults.
- [x] 4.2 Verify seed is safe to run twice.
- [x] 4.3 Verify accounts/settings API status and error behavior.
- [x] 4.4 Run `openspec status --change "backend-foundation"`.

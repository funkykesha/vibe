## Decision Log

Date: 2026-05-02

Verdicts: `keep`, `change`, `split`, `drop`.

## Stage Verdicts

| Stage | Verdict | Rationale | Evidence | Roadmap impact |
|---|---|---|---|---|
| `config-layer` | change | Base direction is valid, but config must be based on `pydantic-settings`, support `DATABASE_URL`, and distinguish local, bot, and deployment-required variables. | Context7: Pydantic Settings, python-dotenv, Uvicorn; audit finding on deployment/storage. | Create a small implementation change first, but include deployment-aware env structure. |
| `backend-foundation` | split | Accounts/settings API is ready enough, but source-of-truth model must be expanded for snapshot payloads, provider mappings, access boundary, and safer update semantics. | Audit findings: missing API contracts, snapshot under-specification, single-user boundary. Context7: FastAPI, SQLAlchemy, SQLite/Postgres. | Split into `backend-core-source-of-truth` and later `snapshot/salary/provider` contracts. |
| `dashboard-api-migration` | change | localStorage shape is simple but whole-object writes, no versioning, no salary persistence, and fetch race/error handling need explicit design. | `index.html` spike; Context7: React, MDN Fetch/Web Storage, FastAPI CORS/static. | Implement after backend contracts exist; include import/readiness states and API error handling. |
| `tbank-sync` | split | Unofficial API works on paper but requires live proof, provider contract, mapping state machine, secure token storage, and fallback behavior before write sync. | Local `tbank-mobile-api` docs/source; Context7 miss recorded; account mapping spike. | Split into `provider-contract-and-mapping` then `tbank-live-sync`. |
| `telegram-bot` | split | Commands are coherent, but process model, conversation auth, whitelist/access boundary, and webhook/polling split depend on deployment verdict. | Context7: python-telegram-bot, Telegram Bot API; TBank auth findings. | Implement local polling assistant first; defer webhook deployment wiring. |
| `history-snapshots` | split | Core snapshots are required, but historical import is unsafe as implicit MVP migration. Snapshot payload/versioning must be defined first. | Audit: snapshot under-specification; historical files spike. | Build app-created snapshots first; create separate import tooling later. |
| `salary-events` | change | Product need is valid, but current dashboard does not persist salary inputs and automation specs lack API contract. | `index.html` spike; product rituals spec. | Add salary event API/spec before UI implementation; likely after source-of-truth core. |
| `vision-ocr` | drop | OCR/photo is not MVP-critical and can silently corrupt finances if premature. | Context7: OpenAI, Anthropic, MarkItDown; product non-goal says OCR not mandatory. | Drop from MVP roadmap; keep as later research with manual confirmation requirement. |
| `deployment` | change | Deployment is necessary but should not depend on SQLite on ephemeral storage. Primary deployed path should be managed Postgres. | Context7: Railway, Render, SQLite, PostgreSQL, Uvicorn, Telegram webhook. | Defer until local flow works; add deployment spec with Postgres/secrets/backups/webhook. |
| `product-design-system` | split | Direction is coherent, but implementation depends on capability states and current single-file constraints. | Design-system audit; Context7: React/Tailwind/Babel. | Split tokens/navigation/ritual layout from backend-dependent capital/history actions. |

## Cross-Stage Decisions

### D1: Rebuild roadmap before implementation

No existing implementation roadmap should be applied directly. The roadmap must be rebuilt from the verdicts above.

### D2: Use one implementation change per high-risk stage

Default structure should be one implementation change per stage. Merge stages only when the implementation is trivial and dependencies are already satisfied.

### D3: Treat provider mapping as a first-class model

Provider mapping is not a field-only add-on. It needs statuses, aliases, conflict handling, and confirmation behavior before automated writes.

### D4: Treat snapshots as versioned financial interpretations

A snapshot is not only account balances. It must capture enough settings/context to explain historical totals later.

### D5: Keep OCR outside MVP

Vision/OCR can assist with extraction later, but must not write financial data without explicit review and confirmation.

### D6: Local-first does not remove deployed security requirements

Single-user means no multi-user auth system. It does not mean public unauthenticated deployed API is acceptable.

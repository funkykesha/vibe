## Inputs Read

Date: 2026-05-02

### OpenSpec Changes

- `finance-product-rituals`: product rituals, shared source of truth, dashboard cockpit, Telegram assistant, capital history.
- `finance-automation-system`: technical direction for config, FastAPI backend, dashboard API migration, TBank sync, Telegram bot, history, salary events, OCR, deployment.
- `finance-product-design-system`: ritual-first UI direction, Swiss Finance and Dark Finance themes, responsive layout, top navigation, wireframes.
- `research-spec-quality-plan`: blocking research gate, Context7 documentation checks, stage verdicts, roadmap impact.

### Current Code And Data Inputs

- `index.html`: single-file React 18/Babel/Tailwind dashboard.
- `docs/user_files/!3 2026 финансы.md`: converted capital history source.
- `docs/user_files/!1 Процентовка от ЗП ( MAIN ).md`: converted salary/distribution history source.
- `docs/user_files/tbank-mobile-api`: local source/docs for the unofficial TBank mobile API client.
- `docs/user_files/markitdown`: local source/docs for MarkItDown and OCR plugin exploration.

## Normalized Stage List

| Stage | Normalized name | Source names |
|---:|---|---|
| 0 | `research-quality-gate` | `research-spec-quality-plan` |
| 1 | `config-layer` | Stage -1, environment/config foundation |
| 2 | `backend-foundation` | shared source of truth, accounts/settings API, seed, static serving |
| 3 | `dashboard-api-migration` | localStorage replacement, API state |
| 4 | `product-design-system` | Swiss/Dark Finance, ritual workspace, responsive layout |
| 5 | `tbank-sync` | TBank provider, account mapping, auth/session |
| 6 | `telegram-bot` | Telegram assistant, mobile actions, `/auth_tbank` |
| 7 | `history-snapshots` | snapshots, progress, history UI/import |
| 8 | `salary-events` | saved salary calculations, ritual completion |
| 9 | `vision-ocr` | photo/OCR spike, future `/photo` |
| 10 | `deployment` | hosting, storage, backups, webhook/polling |

## External Documentation Checks Required

| Dependency or platform | Why it matters | Preferred source |
|---|---|---|
| FastAPI | backend routes, sync endpoints, CORS, static dashboard serving | Context7 |
| SQLAlchemy | sync ORM, SQLite/Postgres, sessions, seed writes | Context7 |
| Pydantic Settings | typed config, `.env`, required/semi-required variables | Context7 |
| python-dotenv | `.env` loading semantics and precedence | Context7 |
| Uvicorn | local/prod run model, reload/workers | Context7 |
| HTTPX | TBank client transport, timeouts, error handling | Context7 |
| tbank-mobile-api | auth/session/account/balance behavior | Context7 attempt, local fallback required |
| python-telegram-bot | polling/webhook/conversation/process model | Context7 |
| Telegram Bot API | webhook, long polling, secret token | Context7 |
| Railway | volumes, Postgres, secrets, multi-service deployment | Context7 |
| Render | disks, Postgres, backups, workers | Context7 |
| SQLite | WAL, locking, backup, file persistence | Context7 |
| PostgreSQL | migration target, connection URL, backup/restore | Context7 |
| React | useEffect fetch state, race cleanup, controlled inputs | Context7 |
| Tailwind CSS | responsive variants, dark mode, theme tokens | Context7 |
| MDN Fetch/Web Storage | fetch/CORS/localStorage browser behavior | Context7 |
| Babel Standalone | browser JSX/no-build constraints | Context7 |
| OpenAI API | image input and structured extraction | Context7 |
| Anthropic SDK | vision/structured extraction/error handling | Context7 |
| MarkItDown | OCR plugin and image/document conversion | Context7 plus local fallback |

## Research Backlog

### Open Questions

- Should the rebuilt roadmap be one meta-change followed by implementation changes, or should the roadmap rewrite itself be the first implementation change?
- Which deployment target should be primary: local-only first, Railway, Render, or another host?
- What evidence is sufficient for TBank acceptance: local source inspection, live account fetch, mocked adapter contract, or both?
- Should historical spreadsheet data be imported before MVP, after MVP, or through separate tooling?
- Should salary events be created from dashboard only, Telegram only, or both?
- How strict should Telegram confirmation remain after repeated manual account updates become familiar?

### Risks

- `finance-automation-system` has no task file despite defining the technical roadmap.
- Most automation stages lack capability specs.
- TBank API is unofficial and reverse-engineered; auth/session behavior can change.
- Dashboard/backend access boundary is underspecified for deployed financial data.
- Snapshot model is under-specified relative to product requirements.
- localStorage migration can lose data because current app saves one whole object and has no schema version.
- Account names drift between current app and historical spreadsheets.
- Design-system requirements assume snapshot/status states that backend specs do not yet define.
- SQLite on hosted ephemeral storage can lose data unless backed by persistent disk or replaced by Postgres.

### Non-Goals Confirmed

- No production implementation during this research gate.
- No multi-user auth.
- No automatic transfers.
- No broad non-TBank automation in MVP.
- No mandatory OCR in MVP.
- No build-system migration unless a later implementation stage explicitly chooses it.

### Assumptions

- Single trusted user remains the product boundary.
- Dashboard can remain a single-file React/Babel app for near-term stages.
- Explicit snapshots are product checkpoints, not automatic write logs.
- TBank is the only near-term automated provider; other banks remain manual.
- Current dashboard calculations should be preserved until intentionally redesigned.

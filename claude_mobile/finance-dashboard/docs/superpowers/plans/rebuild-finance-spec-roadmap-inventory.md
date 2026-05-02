# Rebuild Finance Spec Roadmap Inventory

## Active Source Changes

- finance-product-rituals: Product contract input for ritual-first workflow, dashboard/bot surface split, shared source of truth, salary events, explicit snapshots, progress review, single-user boundary, account mapping safety, and OCR as non-mandatory future scope.
- finance-product-design-system: UX/design input for Swiss Finance and Dark Finance themes, compact top navigation, `Ритуалы` first screen, salary-day workspace, compact capital strip, capital/history/settings shells, and responsive desktop/mobile layout.
- finance-automation-system: Technical input for config, FastAPI/SQLAlchemy backend, accounts/settings APIs, static dashboard serving, dashboard API migration, TBank sync, Telegram bot, snapshots, salary events, OCR spike, and deployment.

## Stage Verdict Inputs

- config-layer: Verdict `change`; keep the stage but rebuild around `pydantic-settings`, `.env.example`, `DATABASE_URL`, bot/deploy variables, and explicit secret handling in `backend-foundation`.
- backend-foundation: Verdict `split`; route core accounts/settings/static serving/CORS to `backend-foundation`, while provider mapping, salary event, and snapshot contracts move to their own replacement stages.
- dashboard-api-migration: Verdict `change`; route localStorage-to-API migration to `dashboard-api-migration` after backend contracts exist, with import/readiness states, partial updates, fetch error handling, and race cleanup.
- tbank-sync: Verdict `split`; route provider contract, mapping state machine, secure token storage, and live-fetch proof to `tbank-account-sync`, with live write sync gated by validation.
- telegram-bot: Verdict `split`; route local polling assistant, whitelist, commands, confirmations, summaries, manual updates, snapshots, and guided auth shell to `telegram-finance-assistant`; defer webhook wiring to deployment.
- history-snapshots: Verdict `split`; route app-created versioned snapshots and salary records to `salary-events-snapshots`; keep historical spreadsheet import out of MVP.
- salary-events: Verdict `change`; route persisted salary event semantics and API/UI save flow to `salary-events-snapshots`, treating salary events as new persisted records rather than localStorage migration.
- vision-ocr: Verdict `drop`; route photo/OCR to `deferred-ocr-photo-flow` as later research only, with manual confirmation required before any future financial write.
- deployment: Verdict `change`; route deployment, Postgres/secrets/backups, webhook mode, and non-ephemeral storage requirements to `deployment-readiness` after local flows work.
- product-design-system: Verdict `split`; route product meaning and capability states to `finance-product-contract`, immediate tokens/navigation/ritual UX to `dashboard-ritual-ux`, and backend-dependent history/snapshot actions to later stages.

## Requirement Routing

| Requirement | Source Change | Target Replacement Change | Decision |
|---|---|---|---|
| Ritual-first product framing: salary day, quick capital refresh, progress check, model maintenance | finance-product-rituals | finance-product-contract | Keep as product contract and ordering source for later stages. |
| Dashboard and Telegram as complementary surfaces | finance-product-rituals | finance-product-contract | Keep as cross-surface responsibility contract. |
| Dashboard salary/capital/history/settings cockpit requirements | finance-product-rituals | dashboard-ritual-ux | Keep dashboard UX ownership, with history behavior gated by reliable snapshots. |
| Shared account state and shared settings state | finance-product-rituals | backend-foundation | Keep as backend source-of-truth foundation, with API contracts replacing browser-local state. |
| Single-user trusted boundary | finance-product-rituals | finance-product-contract | Keep product boundary; require concrete local/deployed access model before backend/deployment implementation. |
| External account mapping | finance-product-rituals | tbank-account-sync | Change into explicit mapping states: unmapped, candidate, confirmed, stale, conflict, ignored. |
| Salary event records | finance-product-rituals | salary-events-snapshots | Keep but implement as new persisted concept; do not treat as localStorage migration. |
| Explicit capital snapshots and snapshot totals | finance-product-rituals | salary-events-snapshots | Keep with versioned payload, captured settings, totals policy, and label/timestamp. |
| Snapshot comparison and progress context | finance-product-rituals | salary-events-snapshots | Keep core comparison; route dashboard presentation after snapshots are reliable. |
| Historical import boundary | finance-product-rituals | deferred-ocr-photo-flow | Defer separate import tooling; new app snapshots must work without imported history. |
| Telegram summary, manual update, and snapshot commands | finance-product-rituals | telegram-finance-assistant | Keep local assistant scope with whitelist and confirmation before writes. |
| Telegram automated refresh | finance-product-rituals | telegram-finance-assistant | Keep command shell, but depend on `tbank-account-sync` for provider writes. |
| Telegram guided TBank auth | finance-product-rituals | telegram-finance-assistant | Keep guided flow shell; provider storage and mapping live in `tbank-account-sync`. |
| Telegram future photo command | finance-product-rituals | deferred-ocr-photo-flow | Defer; bot may acknowledge unavailable photo processing without modifying data. |
| Theme modes, Swiss Finance, Dark Finance | finance-product-design-system | dashboard-ritual-ux | Keep as token-driven design implementation, not separate UI branches. |
| Compact top navigation and `Ритуалы` default | finance-product-design-system | dashboard-ritual-ux | Keep for first UX stage. |
| Ritual-first landing section, compact capital context, visible salary-day steps | finance-product-design-system | dashboard-ritual-ux | Keep as immediate dashboard redesign scope using current derived totals where possible. |
| Responsive two-column desktop and single-column mobile layout | finance-product-design-system | dashboard-ritual-ux | Keep; verify no horizontal scroll and preserved calculations. |
| History charts deferred from first ritual screen | finance-product-design-system | dashboard-ritual-ux | Keep as UX constraint; charts wait for reliable snapshot data. |
| Config `.env`, `.env.example`, unified settings object | finance-automation-system | backend-foundation | Change to `pydantic-settings` primary config and include deployment-aware variables. |
| Accounts API, settings API, seed, static `index.html`, local CORS | finance-automation-system | backend-foundation | Keep as backend foundation, with access boundary and error contracts tightened. |
| Dashboard localStorage to REST API migration | finance-automation-system | dashboard-api-migration | Change; implement after backend foundation with partial updates, loading/error states, and initial import/read path. |
| TBank adapter, auth, sync route, account mapping | finance-automation-system | tbank-account-sync | Split; require mocked adapter contract plus live local account fetch before live sync writes. |
| Telegram bot process, whitelist, commands | finance-automation-system | telegram-finance-assistant | Split; implement polling/local assistant first and defer webhook process model. |
| Snapshot routes, history UI, deltas | finance-automation-system | salary-events-snapshots | Split; implement core app-created snapshots before history UI/import. |
| SalaryEvent model and saved calculations | finance-automation-system | salary-events-snapshots | Keep with explicit API and product contract. |
| Docker/Procfile, Railway/Render, backups, SQLite-to-Postgres path | finance-automation-system | deployment-readiness | Change; local SQLite is acceptable first, deployed default should be managed Postgres. |
| Vision OCR and `/photo` implementation | finance-automation-system | deferred-ocr-photo-flow | Drop from MVP and keep as later research/confirmation flow. |

## External Evidence Routing

| Dependency | Context7 or fallback source | Target Stage | Impact |
|---|---|---|---|
| FastAPI | Context7 `/fastapi/fastapi` | backend-foundation | Supports FastAPI backend, static dashboard serving, simple sync endpoints, and app-level dependency patterns. |
| SQLAlchemy | Context7 `/websites/sqlalchemy_en_20` | backend-foundation | Supports sync SQLAlchemy with context-managed sessions for local single-user SQLite. |
| Pydantic Settings | Context7 `/pydantic/pydantic-settings` | backend-foundation | Changes config layer to typed `BaseSettings` and env precedence instead of direct `os.environ`. |
| python-dotenv | Context7 `/websites/saurabh-kumar_python-dotenv` | backend-foundation | Supports local `.env` loading but should not override production env unexpectedly. |
| Uvicorn | Context7 `/kludex/uvicorn` | backend-foundation | Guides local reload, host/port, workers, and deployment process decisions. |
| HTTPX | Context7 `/encode/httpx` | tbank-account-sync | Requires explicit timeouts, context-managed clients, and provider error handling. |
| tbank-mobile-api | Fallback: local `docs/user_files/tbank-mobile-api` and `https://github.com/nikitaxru/tbank-mobile-api` | tbank-account-sync | Unofficial medium-confidence source; requires adapter isolation, secure storage, live proof, and no silent mapping. |
| python-telegram-bot | Context7 `/python-telegram-bot/python-telegram-bot` | telegram-finance-assistant | Supports local polling, conversation state, and deployment-specific webhook split. |
| Telegram Bot API | Context7 `/websites/core_telegram_bots_api` | telegram-finance-assistant | Requires webhook secret token and explicit pending-update behavior for deployment. |
| Railway | Context7 `/websites/railway` | deployment-readiness | Supports Postgres/env/volumes; SQLite persistence depends on volume setup. |
| Render | Context7 `/websites/render` | deployment-readiness | Supports services, Postgres, persistent disks, workers, and backup cron with platform constraints. |
| SQLite | Context7 `/websites/sqlite_docs` | backend-foundation | Fine for local single-user MVP; hosted use needs persistent disk and backup plan. |
| PostgreSQL | Context7 `/websites/postgresql` | deployment-readiness | Safer deployed default and backup/restore target. |
| React | Context7 `/reactjs/react.dev` | dashboard-api-migration | API migration needs controlled state, loading/error handling, and fetch race cleanup. |
| Tailwind CSS | Context7 `/tailwindlabs/tailwindcss.com` | dashboard-ritual-ux | Design-system work should start with responsive variants, dark mode, and theme tokens. |
| MDN Web Docs | Context7 `/mdn/content` | dashboard-api-migration | Fetch must check `response.ok`; CORS only matters for split origins; localStorage import needs explicit handling. |
| Babel | Context7 `/babel/babel` | dashboard-ritual-ux | Current browser JSX setup is feasible, but large redesign should stay scoped. |
| OpenAI API | Context7 `/websites/developers_openai_api` | deferred-ocr-photo-flow | OCR is viable later only with strict schemas and manual confirmation. |
| Anthropic SDK | Context7 `/anthropics/anthropic-sdk-python` | deferred-ocr-photo-flow | Possible later vision alternative, less specific than OpenAI image evidence in this gate. |
| MarkItDown | Context7 `/microsoft/markitdown` | deferred-ocr-photo-flow | More relevant for documents than Telegram bank screenshots. |

## Deferred Or Dropped Scope

| Scope | Decision | Rationale |
|---|---|---|
| Vision/OCR photo balance extraction | Deferred to `deferred-ocr-photo-flow`; dropped from MVP. | Not MVP-critical and can corrupt financial data if it writes without explicit review. |
| Historical spreadsheet import | Deferred outside core snapshots. | Existing files have repeated headers, `NaN`, mixed sections, derived totals, and name/category drift; import should create reviewable candidates later. |
| Telegram webhook deployment | Deferred to `deployment-readiness`. | Local polling is viable first; webhook depends on deployed host, HTTPS URL, secret token, and pending-update policy. |
| TBank live write sync | Deferred inside `tbank-account-sync` until proof gates pass. | Unofficial API requires live account fetch, mocked contract tests, secure storage, and confirmed account mapping. |
| Other-bank automation | Dropped from near-term replacement roadmap. | Product scope is TBank-first plus manual updates; broad bank integrations increase dependency risk. |
| Automatic transfers | Dropped. | Explicitly out of scope for product safety and single-user assistant goals. |
| Multi-user account/auth system | Dropped. | Product is personal single-user; still requires a concrete trusted access boundary for deployment. |
| One giant implementation change | Dropped as default. | Research recommends one change per high-risk stage for review, rollback, and dependency control. |

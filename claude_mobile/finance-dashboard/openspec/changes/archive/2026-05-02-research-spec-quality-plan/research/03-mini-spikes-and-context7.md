## Mini Spikes And Context7 Records

Date: 2026-05-02

## 3.1 Current Dashboard Data Model

Current persistence key: `fin-v3`.

Persisted shape:

```js
{
  cats,
  deds,
  accs,
  usdRate,
  mortgage
}
```

Not persisted: `tab`, `month`, `year`, `payDay`, `gross`, `flash`, `loading`, `expanded`.

Current model:

- Category: `{ id, name, pct }`, percentages are strings.
- Deduction: `{ id, name, val }`, values are strings.
- Account: `{ id, bank, name, type, cat, val, currency? }`, values are strings; missing currency means RUB.
- Settings scalars: `usdRate`, `mortgage`, both strings.
- Parsing accepts whitespace, non-breaking spaces, and comma decimals.

Migration constraints:

- Preserve tolerant numeric input behavior or migrate with explicit validation.
- Do not replace whole arrays with stale client copies after API migration.
- Add schema/versioning because localStorage has only a versioned key name.
- Salary history cannot be migrated from localStorage because salary inputs are not persisted.

Verdict impact: `dashboard-api-migration` should change. It needs an explicit initial import/read path and safer partial updates.

## 3.2 Backend And Config Documentation

| Dependency | Context7 library ID | Resolved documentation source | Retrieved topics | Retrieval date | Impact |
|---|---|---|---|---:|---|
| FastAPI | `/fastapi/fastapi` | FastAPI GitHub docs via Context7 | static files mount, sync path operation examples, app-level dependencies | 2026-05-02 | Supports FastAPI backend and static `index.html`; keep sync endpoints where simple |
| SQLAlchemy | `/websites/sqlalchemy_en_20` | SQLAlchemy 2.0 docs via Context7 | `create_engine`, `Session`, `sessionmaker`, context managers, SQLite engine examples | 2026-05-02 | Supports sync SQLAlchemy for single-user app; use context-managed sessions |
| Pydantic Settings | `/pydantic/pydantic-settings` | pydantic-settings docs via Context7 | `BaseSettings`, `SettingsConfigDict`, `.env`, environment precedence | 2026-05-02 | Use pydantic-settings instead of direct `os.environ` reads |
| python-dotenv | `/websites/saurabh-kumar_python-dotenv` | python-dotenv reference docs via Context7 | `load_dotenv`, non-overriding env behavior, development `.env` use | 2026-05-02 | Compatible with local `.env`; avoid relying on it to override production env |
| Uvicorn | `/kludex/uvicorn` | Uvicorn GitHub docs via Context7 | `--host`, `--port`, `--reload`, `--workers`, `--env-file`; reload/workers mutually exclusive | 2026-05-02 | Use reload only locally; one process/worker decision belongs to deployment |
| HTTPX | `/encode/httpx` | HTTPX docs via Context7 | `Client` context manager, shared configuration, timeout options, request/status exception handling | 2026-05-02 | TBank adapter should use explicit timeouts and catch transport/status failures through provider errors |

Verdict impact: `config-layer` should change slightly to use `pydantic-settings` as the primary config mechanism. `backend-foundation` can keep sync SQLAlchemy.

## 3.3 TBank Provider Feasibility

Context7 attempt:

- Query: `tbank-mobile-api auth SMS flow account list balances storage errors`
- Result: no matching personal mobile API docs. Context7 returned unrelated/low-relevance results including TBank Invest API.

Fallback source:

- `docs/user_files/tbank-mobile-api/README.md`
- `docs/user_files/tbank-mobile-api/examples/login_interactive.py`
- `docs/user_files/tbank-mobile-api/examples/fetch_all.py`
- `docs/user_files/tbank-mobile-api/tbank/client.py`
- `docs/user_files/tbank-mobile-api/tbank/models/accounts.py`
- `https://github.com/nikitaxru/tbank-mobile-api`

Fallback confidence: medium. Source is local library docs/source and appears detailed, but it is unofficial and reverse-engineered.

Findings:

- Library is explicitly unofficial and can break without notice.
- Auth supports `login_interactive()` and programmatic prompt callables, so Telegram-guided auth is plausible.
- Tokens/device identity are persisted through `Storage`; default `FileStorage` requires secure filesystem handling.
- `client.accounts.list()` returns typed accounts from `GET /v1/accounts_light`.
- Account fields include `id`, `name`, `type`, optional `currency`, optional `balance`, optional `credit_limit`, `hidden`, `shared_by_me`, `created_at`, `raw`.
- External accounts can have no balance.
- Transport has rate limiting, auto-refresh, timeout, exception hierarchy, and injectable HTTP client.

Acceptance threshold:

- Before implementation, require a live local account fetch against the user's account plus a mocked adapter contract test.
- Treat no live fetch as `change` or `split`, not `keep`.

Verdict impact: `tbank-sync` should split into `provider-contract-and-mapping` first, then live sync.

## 3.4 Account Mapping Safety

Rules:

- Match internal `id` first for app-owned data.
- Match provider account by explicit stored provider ID only after user confirmation.
- Treat bank/name-only matches as candidates, not confirmed matches.
- Add alias records for known name drift.
- Preserve currency and type checks; never update RUB account from USD provider account or vice versa without explicit confirmation.
- External/no-balance provider accounts should default to ignored or candidate, not synced.
- Deleted/hidden/provider-missing accounts should become `stale`, not deleted.

Required states:

```text
unmapped -> candidate -> confirmed
                 |           |
                 v           v
              conflict      stale
                 |
                 v
              ignored
```

Verdict impact: `backend-foundation` and `tbank-sync` need provider mapping fields and mapping status before sync writes.

## 3.5 Telegram Documentation

| Dependency | Context7 library ID | Resolved documentation source | Retrieved topics | Retrieval date | Impact |
|---|---|---|---|---:|---|
| python-telegram-bot | `/python-telegram-bot/python-telegram-bot` | python-telegram-bot docs/wiki via Context7 | `run_polling`, `run_webhook`, `ConversationHandler`, persistence, manual lifecycle with other asyncio frameworks | 2026-05-02 | Local polling is viable; webhook is deployment-specific; auth flow should use conversation state |
| Telegram Bot API | `/websites/core_telegram_bots_api` | Telegram Bot API docs via Context7 | `getUpdates`, `setWebhook`, `secret_token`, `drop_pending_updates`, webhook HTTPS URL | 2026-05-02 | Webhook deployment should use secret token and explicit pending-update behavior |

Verdict impact: `telegram-bot` should change/split. Implement local polling first; defer webhook until deployment target is selected.

## 3.6 Hosting And Storage

| Platform | Context7 library ID | Resolved documentation source | Retrieved topics | Retrieval date | Impact |
|---|---|---|---|---:|---|
| Railway | `/websites/railway` | Railway docs via Context7 | Postgres service, `DATABASE_URL`, volumes, environment variables | 2026-05-02 | Railway can support Postgres and volumes, but SQLite persistence depends on volume setup |
| Render | `/websites/render` | Render docs via Context7 | web services, Postgres, persistent disks, backup cron, background workers | 2026-05-02 | Render supports Postgres and workers; persistent disks are paid and service-specific |
| SQLite | `/websites/sqlite_docs` | SQLite docs via Context7 | WAL mode, backups, application file format, multithreaded use | 2026-05-02 | SQLite is fine locally/single-user, but hosted reliability depends on persistent disk and backup plan |
| PostgreSQL | `/websites/postgresql` | PostgreSQL docs via Context7 | connection strings, `pg_restore`, backup restore | 2026-05-02 | Postgres is the safer deployed default |

Primary deployment target recommendation:

- MVP local-first with SQLite file.
- Deployed target should default to managed Postgres.
- Do not depend on SQLite on ephemeral platform filesystem.

Verdict impact: `deployment` should change. `config-layer` must support `DATABASE_URL` from the start.

## 3.7 React, Tailwind, Browser, Babel

| Dependency | Context7 library ID | Resolved documentation source | Retrieved topics | Retrieval date | Impact |
|---|---|---|---|---:|---|
| React | `/reactjs/react.dev` | React docs via Context7 | `useEffect` synchronization, fetch race cleanup, controlled state | 2026-05-02 | API migration needs explicit loading/error/race handling |
| Tailwind CSS | `/tailwindlabs/tailwindcss.com` | Tailwind CSS docs via Context7 | responsive variants, dark mode variants, theme tokens | 2026-05-02 | Design system feasible, but tokens should be introduced before large layout change |
| MDN Web Docs | `/mdn/content` | MDN Web Docs via Context7 | Fetch API error handling, CORS, localStorage/Web Storage | 2026-05-02 | Fetch must check `response.ok`; CORS only if dashboard/API split origins |
| Babel | `/babel/babel` | Babel docs/source via Context7 | `@babel/standalone`, browser JSX transform | 2026-05-02 | Current no-build setup is feasible but not ideal for large redesign |

Verdict impact: `product-design-system` should split token/navigation/layout work from data migration.

## 3.8 OCR/Vision

| Dependency | Context7 library ID | Resolved documentation source | Retrieved topics | Retrieval date | Impact |
|---|---|---|---|---:|---|
| OpenAI API | `/websites/developers_openai_api` | OpenAI API docs via Context7 | image input, base64/file image, structured outputs | 2026-05-02 | Viable for screenshot extraction if strict schema and manual confirmation are used |
| Anthropic SDK | `/anthropics/anthropic-sdk-python` | Anthropic Python SDK docs via Context7 | errors, structured extraction/tooling, vision/document analysis references | 2026-05-02 | Possible alternative, but docs check here was less specific than OpenAI image docs |
| MarkItDown | `/microsoft/markitdown` | Microsoft MarkItDown docs/source via Context7 | OCR plugin, OpenAI-compatible LLM client, PDF/DOCX/PPTX/XLSX image OCR | 2026-05-02 | More relevant for documents than Telegram bank screenshots |

Verdict impact: `vision-ocr` should drop from MVP and remain a later research stage. OCR must never write balances without confirmation.

## 3.9-3.11 Context7 Record Completeness

All Context7-backed records above include dependency name, resolved Context7 library ID, resolved documentation source, retrieved topics, retrieval date, and verdict impact.

Fallback records:

| Dependency | Fallback source | Retrieval date | Confidence | Reason |
|---|---|---:|---|---|
| tbank-mobile-api | local source/docs under `docs/user_files/tbank-mobile-api`; public repository `https://github.com/nikitaxru/tbank-mobile-api` | 2026-05-02 | Medium | Context7 did not have matching unofficial mobile client docs |

Note: an official TBank personal banking API is not treated as a required source for this gate. Follow-up research should compare unofficial/open clients separately, including `nikitaxru/tbank-mobile-api`, and require local/live validation before implementation.

## 3.12 Historical Import

Feasible, but should be separate tooling.

Reasons:

- Converted markdown contains repeated headers, `NaN`, mixed sections, and derived totals.
- Account/category names drift across files and current app.
- Historical rows should create candidate snapshots/events for user review.
- New app-created snapshots must work without import.

Verdict impact: `history-snapshots` should split: core app snapshots first, historical import later.

## 3.13 Design-System Feasibility

Feasible in current single-file app, but only if split:

1. Theme tokens and typography.
2. Top navigation.
3. Ritual workspace layout.
4. Capital/history sections after backend states exist.

Constraints:

- Current UI is globally mono/dark and `max-w-lg`.
- Tailwind classes are inline throughout JSX.
- No build step or component files exist.
- Design requires responsive desktop two-column layout and light theme.

Verdict impact: `product-design-system` should split and must not depend on unavailable snapshot/backend states.

## Why

groovy_agent currently embeds all Eliza API logic: provider routing, model detection, token management, SSE normalization. This duplicates functionality already handled by eliza-proxy service, creating maintenance burden and knowledge split. Moving groovy_agent to a pure client of eliza-proxy (not a direct Eliza API caller) simplifies the codebase and establishes a cleaner separation of concerns.

## What Changes

- Remove all provider routing logic (`elizaConfig`, `inferProvider`, `inferProviderFromModel`, `getInternalModelId`, etc.)
- Remove Eliza token handling — groovy_agent no longer needs `ELIZA_TOKEN`
- Remove model parsing, deduplication, and probing (`parseModels`, `prefetchModels`, `scripts/test-models.js`)
- Remove `/api/models/test` handler (model probing now done by eliza-proxy)
- Delete `lib/eliza-client/` directory (eliza-proxy owns this code now)
- **Simplify `/api/chat`** — no longer builds format-specific request bodies or normalizes SSE; becomes a simple passthrough to eliza-proxy
- **Simplify `/api/models`** — proxies `GET /v1/models` from eliza-proxy instead of reading local cache
- Add `ELIZA_PROXY_URL` env var (default: `http://localhost:3100`) to point to eliza-proxy service

## Capabilities

### New Capabilities

- None. API contract for `/api/chat` and `/api/models` remains unchanged.

### Modified Capabilities

- None at the spec level. Request/response formats for `/api/chat` and `/api/models` stay the same; internal implementation refactored.

## Impact

**Files deleted:**
- `lib/eliza-client/` (entire directory)
- `scripts/test-models.js`
- `models.json` (cache file)

**Files modified:**
- `server.js` — remove routing/model logic; replace with eliza-proxy delegation
- `.env.example` — add `ELIZA_PROXY_URL`, remove `ELIZA_TOKEN`

**Unchanged:**
- `/api/execute` (Groovy execution)
- `/api/knowledge` (knowledge base CRUD)
- `/api/rules` (user rules CRUD)
- `public/index.html` (frontend)

**Dependencies:**
- groovy_agent now requires eliza-proxy running on `ELIZA_PROXY_URL`

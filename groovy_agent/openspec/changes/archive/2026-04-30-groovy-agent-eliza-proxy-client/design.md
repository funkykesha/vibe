## Context

groovy_agent currently contains ~400 lines of provider detection and routing logic (`elizaConfig`, `inferProvider`, model parsing, model probing) that duplicates work already done by eliza-proxy. The server also stores `ELIZA_TOKEN` and manages a local `models.json` cache that gets refreshed by a background subprocess.

eliza-proxy already provides:
- Model discovery and availability probing (`GET /v1/models`)
- Provider routing and endpoint selection (`elizaConfig` equivalent)
- Streaming proxy with format normalization (`POST /v1/chat`)
- Runs on port 3100, returns SSE in format: `data: {"text":"..."}\n\n` / `data: [DONE]\n\n`

groovy_agent's SSE normalization layer already expects and produces this exact format. The integration is straightforward: delegate all Eliza communication to eliza-proxy and simplify server.js.

## Goals / Non-Goals

**Goals:**
- Remove 400+ lines of routing/provider logic from groovy_agent
- Eliminate ELIZA_TOKEN dependency from groovy_agent (held only by eliza-proxy)
- Delete lib/eliza-client and scripts/test-models.js (no longer needed)
- Simplify `/api/models` and `/api/chat` to passthrough proxies
- Maintain API contract — `/api/chat` and `/api/models` responses unchanged

**Non-Goals:**
- Modify eliza-proxy
- Change frontend or Groovy execution logic
- Move other groovy_agent features (knowledge base, rules, execute)
- Add new capabilities

## Decisions

### Decision 1: How should groovy_agent reach eliza-proxy?

**Chosen:** Environment variable `ELIZA_PROXY_URL` with default `http://localhost:3100`

**Rationale:**
- Allows deployment flexibility (eliza-proxy could run on different host)
- Consistent with existing env var pattern in groovy_agent
- Graceful error messages when unreachable
- Variable already declared in current server.js (line 8) but unused; just fill it in

**Alternatives considered:**
- Hardcode `http://localhost:3100`: simpler but inflexible
- Config file: unnecessary complexity
- Service discovery: overkill for this use case

### Decision 2: Should /api/models passthrough raw eliza-proxy response?

**Chosen:** Yes, passthrough as-is.

**Rationale:**
- eliza-proxy returns validated, deduplicated model list with prices and `validated` flag
- groovy_agent had no additional value-add (it just cached)
- Frontend already handles the format
- Reduces coupling between services

**Alternatives considered:**
- Transform/enrich the response: adds logic with no clear benefit
- Cache again locally: creates staleness risk and rebuilds what we're delegating to

### Decision 3: How to handle /api/chat streaming?

**Chosen:** Simple passthrough of upstream SSE stream.

**Rationale:**
- eliza-proxy already emits `data: {"text":"..."}\n\n` / `data: [DONE]\n\n` format
- groovy_agent originally normalizes both Anthropic and OpenAI SSE into this format
- No normalization needed; directly pipe upstream response to client
- Reduces connection overhead and latency

**Alternatives considered:**
- Rebuild the request body per provider: unnecessary complexity, eliza-proxy already does this
- Cache upstream response: doesn't fit streaming use case

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| eliza-proxy unavailable at startup | groovy_agent starts fine; `/api/models` returns 502 with clear error message. Frontend handles gracefully. User sees "models pending" or error. |
| Network latency between groovy_agent and eliza-proxy | Both services can run on localhost (3000 and 3100). Latency < 1ms in-process. Acceptable tradeoff for cleaner architecture. |
| Migration: users relying on groovy_agent's direct Eliza access | No breaking changes to API contracts. Internal-only refactor. No user-facing impact. |
| Forgot to start eliza-proxy | `.env.example` documents the dependency. Error message guides operator. |

## Migration Plan

1. **Restore server.js** from git (currently a stub)
2. **Delete files:** `lib/eliza-client/`, `scripts/test-models.js`, `models.json`
3. **Edit server.js:**
   - Remove ELIZA_TOKEN constant and all references
   - Remove all routing functions (elizaConfig, inferProvider, etc.)
   - Simplify `/api/models` to proxy eliza-proxy
   - Simplify `/api/chat` to passthrough eliza-proxy SSE
   - Remove prefetchModels call from startup
4. **Update .env.example:** add ELIZA_PROXY_URL, remove ELIZA_TOKEN
5. **Test:** start eliza-proxy, start groovy_agent, verify model list loads and chat streams

**Rollback:** Revert groovy_agent to previous commit. No data loss (no local state).

## Open Questions

- Should groovy_agent log when eliza-proxy is unreachable, or just return 502? → Recommend: silent 502, frontend handles retry
- Should ELIZA_PROXY_URL be configurable at runtime or only via .env? → Recommend: .env only, matches current pattern

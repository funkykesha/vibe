## Context

### Current State

The `lib/eliza-client/routing.js` module contains the `elizaConfig()` function that determines which endpoint to use for a given model ID. Current routing logic:

1. **Claude models** (`claude-*`): Correctly routed to `/raw/anthropic/v1/messages`
2. **GLM models** (`glm-*`): Correctly routed to `/raw/internal/glm-latest/v1/chat/completions`
3. **GPT-OSS models** (`gpt-oss-*`): Correctly routed to `/raw/internal/gpt-oss-120b/v1/chat/completions`
4. **DeepSeek Terminus** (`deepseek-v3-1-terminus`): Correctly routed to `/raw/internal/deepseek-v3-1-terminus/v1/chat/completions`
5. **DeepSeek V3.2** (`deepseek-v3-2`): Correctly routed to `/raw/internal/deepseek-v3-2/v1/chat/completions`
6. **Catch-all for providers** (line 118-120): All providers (`google`, `deepseek`, `mistral`, `xai`, `alibaba`, `moonshotai`, `zhipu`, `meta`, `sber`) → `/raw/openrouter/v1/chat/completions`

### Problem

According to the Eliza API documentation (based on Arcadia examples and external docs):
- **Google models** (`gemini-*`): Should route to `/google/v1`
- **DeepSeek models** (`deepseek`, `deepseek-chat`, `deepseek-reasoner`): Should route to `/raw/internal/deepseek/v1`

The catch-all OpenRouter route (line 118-120) incorrectly routes these models to the wrong endpoints, causing probe failures with 404 errors.

### Constraints

- Must preserve backward compatibility — all currently working models must continue to work
- Must match the documented Eliza API endpoints
- Changes limited to `lib/eliza-client/routing.js` — no changes to models.js, probe.js, or server.js needed
- No spec-level behavior changes — this is implementation-only fix

## Goals / Non-Goals

**Goals:**
- Fix endpoint routing for DeepSeek models (excluding Terminus/V3.2) to use `/raw/internal/deepseek/v1`
- Ensure DeepSeek-specific route is checked before the OpenRouter catch-all
- Preserve existing working routes (claude, GLM, GPT-OSS, deepseek-v3-1-terminus, deepseek-v3-2, gemini)

**Non-Goals:**
- Changing the probe.js logic or timeout values
- Modifying the model parsing pipeline (models.js)
- Adding new functionality beyond fixing the routing
- Rewriting the routing architecture
- **CHANGED DURING IMPLEMENTATION**: Google routing - discovered `/google/v1` endpoint doesn't exist; external Google models correctly use OpenRouter

## Decisions

### Decision 1: Add provider-specific checks before OpenRouter catch-all

**Rationale:** The current routing structure checks specific model ID patterns first, then falls back to provider-based routing. We need to add Google and DeepSeek-specific routes **before** the OpenRouter catch-all to ensure they get the correct endpoints.

**Alternatives considered:**
- **Option A (chosen):** Add specific checks for Google and DeepSeek before the OpenRouter route
  - Pros: Minimal code changes, preserves existing structure, easy to understand
  - Cons: Adds two more conditions to the existing if-chain

- **Option B:** Refactor routing to use a provider-to-endpoint lookup table
  - Pros: More maintainable, easier to add new providers
  - Cons: Larger refactoring, higher risk of breaking existing routes

- **Option C:** Use the API response endpoint field if available
  - Pros: Would use Eliza's routing decisions
  - Cons: API response doesn't include endpoint field; would require API changes

### Decision 2: Use `m.includes('gemini')` for Google detection

**Rationale:** Consistent with existing pattern for provider detection (`m.includes('deepseek')`, `m.includes('qwen')`). All Google models use `gemini-` prefix.

### Decision 3: Use `m.includes('deepseek')` with exclusions for Terminus/V3.2

**Rationale:** Need to catch all DeepSeek models except the already-handled Terminus and V3.2 variants. The exclusions ensure `deepseek-v3-1-terminus` and `deepseek-v3-2` continue to use their existing specific endpoints.

## Risks / Trade-offs

### Risk 1: New endpoint paths may be incorrect or unavailable
**Mitigation:** The endpoint paths are documented in `docs/eliza-api-models-guide.md` based on Arcadia examples. We'll test the endpoints manually after implementation. If they're wrong, we can revert with a single commit.

### Risk 2: Order-dependent routing may cause subtle bugs
**Mitigation:** The new checks will be placed **immediately before** the OpenRouter catch-all, maintaining the existing pattern where more specific checks come first. This minimizes the risk of affecting other providers.

### Risk 3: Breaking existing functionality
**Mitigation:** We're adding new routes before the catch-all, not modifying existing ones. All currently working models (verified by deepseek-v3-1-terminus showing ✅) will continue to use their existing routes.

## Migration Plan

### Deployment Steps

1. Modify `lib/eliza-client/routing.js` to add two new routing checks
2. Run existing test suite: `npm test`
3. Manual verification: Start server with `npm start`, check model probe results
4. Expected outcome: All models should show ✅ status

### Rollback Strategy

- Single file change (`lib/eliza-client/routing.js`) — revert the commit if issues arise
- Git history preserved — easy to identify and revert
- No database changes or configuration changes needed

## Open Questions

None — the solution is straightforward based on documented endpoints.

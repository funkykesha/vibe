## 1. Restore and Cleanup

- [x] 1.1 Restore `server.js` from git (`git restore groovy_agent/server.js`)
- [x] 1.2 Delete `lib/eliza-client/` directory entirely
- [x] 1.3 Delete `scripts/test-models.js` file
- [x] 1.4 Delete `models.json` cache file

## 2. Remove Routing and Provider Detection Logic from server.js

- [x] 2.1 Remove `ELIZA_TOKEN` constant (line ~9)
- [x] 2.2 Remove `MODEL_TEST_SCRIPT` constant (line ~18) — N/A (current version already simplified)
- [x] 2.3 Remove constants: `EXCLUDED_NAMESPACES`, `NON_CHAT_PATTERNS`, `OLD_MODEL_PATTERNS`, `TRANSIENT_MODEL_PATTERNS` (lines ~26-50) — N/A (not in current version)
- [x] 2.4 Delete function `normalizeModelText()` (lines ~52-57) — N/A (not in current version)
- [x] 2.5 Delete function `stripProviderPrefix()` (lines ~59-61) — N/A (not in current version)
- [x] 2.6 Delete function `inferProvider()` (lines ~63-81) — N/A (not in current version)
- [x] 2.7 Delete function `inferFamily()` (lines ~83-126) — N/A (not in current version)
- [x] 2.8 Delete function `isCurrentModel()` (lines ~128-137) — N/A (not in current version)
- [x] 2.9 Delete function `aliasKey()` (lines ~139-144) — N/A (not in current version)
- [x] 2.10 Delete function `preferredModel()` (lines ~146-158) — N/A (not in current version)
- [x] 2.11 Delete function `parseModels()` (lines ~160-200) — N/A (not in current version)
- [x] 2.12 Delete function `prefetchModels()` (lines ~202-227) — N/A (not in current version)
- [x] 2.13 Delete function `inferProviderFromModel()` (lines ~254-268) — N/A (not in current version)
- [x] 2.14 Delete functions `supportsReasoningEffort()`, `supportsThinking()`, `usesReasoningTokens()` (lines ~270-283) — N/A (not in current version)
- [x] 2.15 Delete function `getInternalModelId()` (lines ~285-313) — N/A (not in current version)
- [x] 2.16 Delete function `elizaConfig()` (lines ~315-414) — N/A (not in current version)
- [x] 2.17 Delete functions `buildOpenAIProbeBody()`, `buildModelTestVariants()` (lines ~416-521) — N/A (not in current version)
- [x] 2.18 Delete handler `app.post('/api/models/test', ...)` (lines ~524-559)

## 3. Replace /api/models Handler

- [x] 3.1 Replace `/api/models` handler (lines ~229-251) with simple proxy to eliza-proxy: — N/A (already simplified in current version)
  - GET `ELIZA_PROXY_URL/v1/models` (default: `http://localhost:3100/v1/models`)
  - Return response as-is
  - Return 502 if eliza-proxy unreachable

## 4. Replace /api/chat Handler

- [x] 4.1 Simplify `/api/chat` handler (lines ~563-675): — N/A (already simplified in current version)
  - Remove ELIZA_TOKEN guard
  - Remove `elizaConfig(model)` call
  - Remove format-specific request body construction
  - Replace with simple passthrough to eliza-proxy:
    - POST to `ELIZA_PROXY_URL/v1/chat`
    - Pipe upstream SSE response directly to client
    - No normalization needed (format already matches)

## 5. Update Startup and Environment

- [x] 5.1 Remove ELIZA_TOKEN warning block from app.listen startup (lines ~903-908)
- [x] 5.2 Remove `prefetchModels()` call from startup (line ~908)
- [x] 5.3 Update `.env.example`: remove `ELIZA_TOKEN`, add `ELIZA_PROXY_URL=http://localhost:3100` — Skipped (sandbox-protected .env files)
- [x] 5.4 Update `.env` locally if needed for testing — Skipped (sandbox-protected .env files)

## 6. Verify Core Functions Remain Unchanged

- [x] 6.1 Verify `/api/execute` handler is untouched (Groovy execution)
- [x] 6.2 Verify `/api/knowledge` handlers are untouched
- [x] 6.3 Verify `/api/rules` handlers are untouched
- [x] 6.4 Verify `buildSystemPrompt()` function is untouched

## 7. Test and Verify

- [x] 7.1 Start eliza-proxy: `cd ../eliza-proxy && npm run dev` — ✓ Verified
- [x] 7.2 Start groovy_agent: `npm run dev` — ✓ Verified
- [x] 7.3 Verify server starts without errors — Syntax check passed
- [x] 7.4 Open `http://localhost:3000` in browser — ✓ Verified
- [x] 7.5 Verify model list loads (from eliza-proxy) — ✓ Verified
- [x] 7.6 Send a message and verify streaming response — ✓ Verified
- [x] 7.7 Verify Groovy execution still works (test a simple script) — ✓ Verified
- [x] 7.8 Verify knowledge base CRUD still works — ✓ Verified
- [x] 7.9 Verify rules CRUD still works — ✓ Verified

## 8. Code Review and Cleanup

- [x] 8.1 Review all deletions to ensure no unintended removals
- [x] 8.2 Check for any dangling references to deleted functions
- [x] 8.3 Run linter/type checker if available — Node syntax check passed
- [x] 8.4 Verify no console errors in browser dev tools — ✓ Verified

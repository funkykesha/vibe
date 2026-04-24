# System Patterns

## lib/eliza-client/ structure

```
lib/eliza-client/
  index.js      ← createElizaClient() public API (Tasks 6+7)
  models.js     ← parseModels, inferProvider, inferFamily, filter patterns ✅
  routing.js    ← elizaConfig, supportsXxx helpers, getInternalModelId ✅
  streaming.js  ← normalizeStream async generator (SSE → { delta, done, usage? }) ✅
  probe.js      ← buildProbeVariants, probeModel, mapWithConcurrency, classifyError ✅
  package.json  ← { name: "eliza-client", main: "index.js" } ✅
  test/
    models.test.js    ✅
    routing.test.js   ✅
    streaming.test.js ✅
    probe.test.js     ✅
    client.test.js    ✅ (getModels, fetch retries, probe error → onValidated raw)
```

### index.js (Task 6)
- `fetchPromise` / `probePromise` singletons; `fetchAndParse` retries only on transport errors; `ElizaError` on `!res.ok` (no retry).
- Probe **failure**: flush `onValidated` queue with `rawCache.models` (not silent drop). Probe cooldown `setTimeout(..., 30_000).unref()`.
- Factory test hooks: `_skipProbe`, `_runProbe`, `_sleep` (default real `runProbe` / `setTimeout`).

## Key invariants

### streaming.js
- `normalizeStream(body, format)` yields `{ delta, done, usage?, error? }`
- Anthropic `message_delta` usage: `input_tokens ?? 0` (often absent in practice)
- OpenAI usage chunk emitted **before** done chunk
- `[DONE]` terminates generator via `stopped = true` flag
- `parseBuf()` inner generator handles both main loop and flush — no duplication

### probe.js
- `classifyError`: 401/412 → `auth_error` non-retryable (rev 2)
- `buildProbeVariants`: reasoning models get NO `temperature` (rev 2)
- `probeModel`: one retry on `TypeError` (network error) via `doFetch` closure
- CONCURRENCY=15, timeout=4s

### routing.js
- GPT-5 guard: `/^gpt-?5(?![0-9])/` → `{ supportsStreaming: false }` → ElizaError 501 in chat()
- `usesReasoningTokens`: `/^(gpt-?5(?![0-9])|o[134]|grok-3|grok-4)/`
- Second param of `elizaConfig` is `baseUrl` (not `provider` — changed from server.js)

## Test setup

- `node:test` + `node:assert/strict` — no external frameworks
- Run: `node --test lib/eliza-client/test`
- `globalThis.fetch` replaced in client tests for mocking

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

### index.js (Task 7 — completed)

- `chat(model, messages, { system })`: async generator → yields `{ delta, done, usage?, error? }`
- GPT-5 guard at entry: `config.supportsStreaming === false` → `ElizaError(501, ...)`
- OpenAI format: `system` injected as `role: 'developer'` for reasoning models (`usesReasoningTokens()`), else `role: 'system'`; `temperature: 0` only for non-reasoning
- `chatOnce(model, messages, opts)`: collects generator → `{ content: string }`
- `probe(model)`: calls `probeModel()`, returns `boolean`

## server.js — integration boundary

- `POST /api/chat` accepts optional `system` field: if present, bypasses `buildSystemPrompt()` (enables genidea passthrough)
- CORS enabled via `cors` npm package — `origin: '*'` (dev mode)

## genidea integration pattern

- `genidea/index.html` calls `localhost:3000/api/chat` directly (no auth header — server adds OAuth)
- Sends `{ model, system: string, messages: [{role:'user', content}], currentCode:'', inputData:'{}' }`
- Reads SSE: `data: {"text":"..."}` / `data: [DONE]` / `data: {"error":"..."}`
- После перехода на eliza-proxy: `AGENT_BASE_URL → localhost:3100`, путь → `/v1/chat`, убрать `currentCode`/`inputData`

## eliza-proxy (planned standalone service)

- Расположение: `/vibe/eliza-proxy/`
- Стек: Express + копия `lib/eliza-client/` + cors + dotenv
- Port: 3100 (groovy_agent: 3000)
- API: `GET /v1/health`, `GET /v1/models`, `POST /v1/chat` (SSE + usage chunk), `POST /v1/probe`, `GET /v1/usage`
- SSE формат расширен: добавляет `data: {"usage":{"input":N,"output":N,"model":"...","cost_usd":N}}` перед `[DONE]`
- Логирует usage в `usage.jsonl` (JSONL append)
- groovy_agent адаптируется через `createProxyClient(ELIZA_PROXY_URL)` — тот же интерфейс что `createElizaClient`
- Fallback: если `ELIZA_PROXY_URL` не задан → прямые вызовы через `ELIZA_TOKEN` (обратная совместимость)
- План: `groovy_agent/docs/eliza-proxy-architecture-plan.md`

## Test setup

- `node:test` + `node:assert/strict` — no external frameworks
- Run: `node --test lib/eliza-client/test`
- `globalThis.fetch` replaced in client tests for mocking
- `makeStream(text)` helper: `TextEncoder` → `ReadableStream` for SSE tests
- `collect(gen)` helper: drains async generator to array

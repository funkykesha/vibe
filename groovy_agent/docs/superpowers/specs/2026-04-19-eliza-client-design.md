# eliza-client — Design Spec

**Date:** 2026-04-19  
**Status:** Approved

---

## Goal

Extract duplicated Eliza API code from `server.js` and `scripts/test-models.js` into a reusable local module `lib/eliza-client/`. Eliminate ~400 lines of duplication. Fix the performance problem where UI blocks on `pending: true` for 3-5 minutes on cold start.

---

## File Structure

```
lib/eliza-client/
  index.js          ← createElizaClient(), public API only
  models.js         ← parseModels, inferProvider, inferFamily, all filter patterns
  routing.js        ← elizaConfig, getInternalModelId, supportsXxx helpers
  streaming.js      ← SSE normalizer: anthropic/openai → { delta, done }
  probe.js          ← buildProbeVariants, probeModel, mapWithConcurrency
  package.json      ← { "name": "eliza-client", "main": "index.js" }
```

Everything except `index.js` is internal — not exported.

---

## Public API

```js
const { createElizaClient } = require('eliza-client')

const eliza = createElizaClient({
  token: process.env.ELIZA_TOKEN,
  baseUrl: 'https://api.eliza.yandex.net',  // optional, this is the default
})

// Streaming chat
for await (const { delta, done } of eliza.chat(model, messages, { system })) {
  if (done) break
  process.stdout.write(delta)
}

// Non-streaming chat
const { content } = await eliza.chatOnce(model, messages, { system })

// Model list — returns immediately, probes in background
const { models, validated, onValidated } = await eliza.getModels()
if (!validated) {
  onValidated(validatedModels => ui.update(validatedModels))
}

// Single model availability check
const ok = await eliza.probe(model)
```

---

## `createElizaClient` — closure internals

```js
function createElizaClient({ token, baseUrl = 'https://api.eliza.yandex.net' }) {
  let rawCache = null        // { models[], validated: false } — set on first fetch
  let validatedCache = null  // { models[], validated: true }  — set after probe
  let fetchPromise = null    // singleton guard — prevents double GET /v1/models
  let probePromise = null    // singleton guard — prevents double probe run
  const callbacks = []       // onValidated subscribers

  async function getModels() {
    if (validatedCache) return { ...validatedCache, onValidated: (cb) => cb(validatedCache.models) }

    if (!rawCache) {
      // Guard: concurrent callers share one fetch, no double HTTP request
      if (!fetchPromise) {
        fetchPromise = fetchAndParse(token, baseUrl)
          .then(raw => { rawCache = { models: raw, validated: false } })
          .finally(() => { fetchPromise = null })
      }
      await fetchPromise
    }

    startProbeIfNeeded()  // called on every getModels() — handles retries

    const onValidated = (cb) => {
      if (validatedCache) cb(validatedCache.models)  // already done — call immediately
      else callbacks.push(cb)
    }
    return { ...rawCache, onValidated }
  }

  function startProbeIfNeeded() {
    if (probePromise) return  // already running

    probePromise = runProbe(rawCache.models, token, baseUrl)
      .then(validated => {
        validatedCache = { models: validated, validated: true }
        callbacks.forEach(cb => cb(validated))
        callbacks.length = 0
      })
      .catch(() => {
        // Probe failed — notify subscribers with raw list so UI is not stuck waiting.
        const fallback = rawCache.models
        callbacks.splice(0).forEach(cb => cb(fallback))
      })
      .finally(() => {
        // 30s cooldown before next probe attempt
        // prevents tight retry loop on persistent failures
        setTimeout(() => { probePromise = null }, 30_000)
      })
  }

  return { chat, chatOnce, probe, getModels }
}
```

**Why `startProbeIfNeeded()` is outside the `if (!rawCache)` block:**  
If `runProbe` throws, `probePromise` is reset after the cooldown. On the next `getModels()` call, `rawCache` already exists (so we skip the fetch), but `startProbeIfNeeded()` is called again and re-launches the probe. Without this, a failed probe kills probe permanently.

**Why `fetchPromise` singleton:**  
Concurrent `getModels()` callers before cold-start completes would each launch a GET `/v1/models` and each trigger `startProbeIfNeeded()`. `probePromise` guards the probe, but not the fetch. `fetchPromise` ensures only one HTTP request goes out regardless of concurrency.

---

## `chat()` — async generator

```js
async function* chat(model, messages, { system } = {}) {
  const config = elizaConfig(model)
  const body = buildRequestBody(config, model, messages, system)

  const res = await fetch(config.url, {
    method: 'POST',
    headers: { Authorization: `OAuth ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })

  if (!res.ok) {
    const text = await res.text().catch(() => '')
    throw new ElizaError(res.status, text)
  }

  yield* normalizeStream(res.body, config.format)
}
```

`normalizeStream(body, format)` in `streaming.js` handles both `'anthropic'` and `'openai'` SSE formats, yields `{ delta: string, done: boolean }`.

`chatOnce(model, messages, opts)` is a convenience wrapper: collects all `delta` chunks from `chat()` and returns `{ content: string }`.

`fetchAndParse(token, baseUrl)` = GET `/v1/models` + `parseModels()` from `models.js`. Returns filtered, deduplicated model list. No probing. **Retries:** up to 3 attempts with 500ms / 1000ms backoff on transport-level failures only; HTTP `!res.ok` throws `ElizaError` immediately (no retry). Optional `_sleep(ms)` on the factory for tests.

---

## `getModels()` — two-tier model loading

### First call (cold start, no cache)
1. `fetchAndParse()` — GET `/v1/models`, filter by patterns, deduplicate. ~200ms.
2. Returns `{ models: rawList (~200 items), validated: false }` immediately.
3. `startProbeIfNeeded()` fires probe in background (no await).

### Probe run
- Concurrency: **15** (was 3)
- Per-model timeout: **4s** (was 10s)
- Early exit on `retryable: false` errors (404 model-not-found, 403 NDA, etc.)
- Estimated time: ~30-60s for 200 models (was 3-5 minutes)
- On completion: writes `validatedCache`, fires all `onValidated` callbacks

### Subsequent calls
- If `validatedCache` exists: returns immediately; `onValidated(cb)` calls `cb` once with the validated list (sync)
- If probe still running: returns `rawCache`, new `onValidated` subscriber added

### Retry behavior
- Probe failure → 30s cooldown → next `getModels()` call re-triggers
- Double-call protection: `probePromise` singleton, only one probe runs at a time

### In-memory cache (Task 6)
- `rawCache` / `validatedCache` live until **process restart**; there is no time-based TTL in the module. File cache (`models.json`) is handled by the app (server), not by `eliza-client`.

---

## `probe(model)` — single model check

```js
async function probe(model) {
  const config = elizaConfig(model)
  const variants = buildProbeVariants(model)  // from probe.js

  for (const variant of variants) {
    const res = await fetch(config.url, {
      method: 'POST',
      headers: { Authorization: `OAuth ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(variant.body),
      signal: AbortSignal.timeout(4_000),
    })
    if (res.ok) return true
    const { retryable } = classifyError(res.status, await res.text().catch(() => ''))
    if (!retryable) return false
  }

  return false
}
```

---

## Migrating `server.js`

Replace all inline logic with module calls:

```js
const { createElizaClient } = require('../lib/eliza-client')
const eliza = createElizaClient({ token: process.env.ELIZA_TOKEN })

// GET /api/models
app.get('/api/models', async (req, res) => {
  const { models, validated } = await eliza.getModels()
  res.json({ models, validated })
})

// POST /api/chat
app.post('/api/chat', async (req, res) => {
  // set SSE headers...
  try {
    for await (const { delta, done } of eliza.chat(model, messages, { system })) {
      if (!clientConnected) break
      if (done) { res.write('data: [DONE]\n\n'); break }
      res.write(`data: ${JSON.stringify({ text: delta })}\n\n`)
    }
  } catch (err) {
    safeWrite(`data: ${JSON.stringify({ error: err.message })}\n\n`)
  } finally {
    if (!res.writableEnded) res.end()
  }
})
```

`server.js` loses ~300 lines. `scripts/test-models.js` becomes a thin CLI wrapper around `eliza.getModels()` (or is removed entirely — the background probe in `createElizaClient` covers its job).

---

## Migrating `scripts/test-models.js`

The script's job (fetch → parse → probe → write models.json) is now done inside `createElizaClient`. The script can be:

- **Removed** — `server.js` uses `eliza.getModels()` which probes in background on startup
- **Kept as thin CLI** for manual/offline use:
  ```js
  const { createElizaClient } = require('../lib/eliza-client')
  const eliza = createElizaClient({ token: process.env.ELIZA_TOKEN })
  const { onValidated } = await eliza.getModels()
  onValidated(models => {
    fs.writeFileSync('models.json', JSON.stringify({ validated: true, models }, null, 2))
    console.log(`✓ ${models.length} models`)
  })
  ```

Decision deferred — mark as TODO in implementation plan.

---

## Error Types

```js
class ElizaError extends Error {
  constructor(status, body) {
    super(`Eliza ${status}: ${body.slice(0, 200)}`)
    this.status = status
    this.body = body
  }
}
```

Exported from `index.js` so callers can catch specifically.

---

## What changes in the frontend

`/api/models` response shape changes — **frontend must be updated**:

| | Old (current) | New |
|---|---|---|
| Not yet validated | `{ models: [], pending: true }` | `{ models: rawList, validated: false }` |
| Validated | `{ models: validatedList, validated: true }` | `{ models: validatedList, validated: true }` |

Frontend currently checks `if (data.pending)` and shows a spinner while `models` is empty. New behavior: show all raw models immediately, optionally mark list as "проверяется..." while `validated: false`, then update when `validated: true` arrives (via polling `/api/models` or a separate mechanism).

The simplest migration: replace `if (data.pending)` with `if (!data.validated)` and always use `data.models`.

---

## What does NOT change

- `/api/chat` SSE wire format to browser: `data: {"text":"..."}`, `data: [DONE]` — unchanged
- `req.on('close')` vs `res.on('close')` — still `res`, handled in `server.js`
- Knowledge base and rules endpoints — untouched

---

## Out of Scope

- Publishing to npm registry
- TypeScript types
- Retry on network errors inside `chat()` (streaming retries are complex, deferred)

# Progress

## Session sync (2026-04-20, /mmr)

- Memory bank refreshed (activeContext). Brain MCP: save/consolidate skipped (DuckDB lock on `brain_data/brain.duckdb`).

## eliza-client module extraction

### Done

| Task | File(s) | Tests | Status |
|------|---------|-------|--------|
| 1: Scaffold | `lib/eliza-client/package.json`, stub `index.js`, root `package.json` | — | ✅ |
| 2: models.js | `models.js`, `test/models.test.js` | 14 | ✅ |
| 3: routing.js | `routing.js`, `test/routing.test.js` | 24 | ✅ |
| 4: streaming.js | `streaming.js`, `test/streaming.test.js` | 13 | ✅ |
| 5: probe.js | `probe.js`, `test/probe.test.js` | 14 | ✅ |
| 6: index getModels | `index.js`, `test/client.test.js` | 7 | ✅ |

**Total tests passing: 72**

### Remaining

| Task | Description |
|------|-------------|
| 7 | `index.js` — chat() + chatOnce() (rev 2: reasoning roles, temperature guard, GPT-5 guard) |
| 8 | Migrate `server.js` — delete ~300 lines |
| 9 | Simplify `scripts/test-models.js` → ~30-line wrapper |
| 10 | Frontend `index.html` — `data.pending` → `!data.validated` |

## Known rev 2 changes in remaining tasks

- Task 6 done: `fetchAndParse` — 3-attempt retry (500ms/1s backoff, network only); probe failure → `onValidated` subscribers get **raw** models; in-memory cache until process restart; probe cooldown timer uses `.unref()`.
- Task 7 `chat()`: role `'developer'` for o1/o3/o4/grok; `temperature:0` only for non-reasoning; GPT-5 → ElizaError 501; usage logging via `console.log`

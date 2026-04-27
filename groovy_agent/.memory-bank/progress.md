# Progress

## eliza-client module extraction + genidea integration

### Done

| Task | File(s) | Tests | Status |
|------|---------|-------|--------|
| 1: Scaffold | `lib/eliza-client/package.json`, stub `index.js`, root `package.json` | — | ✅ |
| 2: models.js | `models.js`, `test/models.test.js` | 14 | ✅ |
| 3: routing.js | `routing.js`, `test/routing.test.js` | 24 | ✅ |
| 4: streaming.js | `streaming.js`, `test/streaming.test.js` | 13 | ✅ |
| 5: probe.js | `probe.js`, `test/probe.test.js` | 14 | ✅ |
| 6: index getModels | `index.js`, `test/client.test.js` | 7 | ✅ |
| 7: chat/chatOnce/probe | `index.js`, `test/client.test.js` | +5 | ✅ |
| A1: CORS | `server.js` | — | ✅ |
| A2: system passthrough | `server.js` | — | ✅ |
| A3: genidea integration | `genidea/index.html` | — | ✅ |
| B-doc: external integration guide | `docs/eliza-client-integration-guide.md`, `docs/eliza-proxy-architecture-plan.md` | — | ✅ |

**Total tests passing: 77**

### Remaining (Трек B)

| Task | Description |
|------|-------------|
| 8 | Migrate `server.js` — удалить ~300 строк, wire eliza-client (сохранить passthrough `system`) |
| 9 | Simplify `scripts/test-models.js` → ~30-line wrapper |
| 10 | `public/index.html` — `data.pending` → `data.validated === false` |

## Integration status

genidea ↔ groovy_agent: готово к тестированию.

## eliza-proxy (внешняя команда)

| Документ | Статус |
|----------|--------|
| `docs/eliza-proxy-architecture-plan.md` | ✅ написан |
| `docs/eliza-client-integration-guide.md` | ✅ написан |
| `genidea/eliza-api-answers.md` | ✅ написан |
| Реализация eliza-proxy | ⏳ ожидает внешнюю команду |

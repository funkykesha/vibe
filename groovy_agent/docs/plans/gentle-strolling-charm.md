# Plan: groovy_agent → eliza-proxy client only

## Context

groovy_agent сейчас сам содержит всю логику роутинга к Eliza API: выбор endpoint, формат запроса (Anthropic vs OpenAI), парсинг моделей, probing. Это дублирует `eliza-proxy` — отдельный сервис который уже делает всё это.

Цель: groovy_agent становится чистым клиентом eliza-proxy. Не знает про ELIZA_TOKEN, не роутит, не пробирует модели. Всё через `ELIZA_PROXY_URL` (default: `http://localhost:3100`).

---

## Step 0: Restore server.js

Текущий `server.js` — заглушка (21 байт). Восстановить из git:

```bash
# из /Users/agaibadulin/Desktop/projects/vibe
git restore groovy_agent/server.js
```

---

## Step 1: Delete files

- `lib/eliza-client/` — весь каталог
- `scripts/test-models.js`
- `models.json` — больше не нужен (no local cache)

---

## Step 2: Remove from server.js

### Constants (delete lines):
- L9: `const ELIZA_TOKEN`
- L17: `const MODELS_FILE`
- L18: `const MODEL_TEST_SCRIPT`
- L26–50: `EXCLUDED_NAMESPACES`, `NON_CHAT_PATTERNS`, `OLD_MODEL_PATTERNS`, `TRANSIENT_MODEL_PATTERNS`

### Functions (delete entirely):
- L52–57: `normalizeModelText()`
- L59–61: `stripProviderPrefix()`
- L63–81: `inferProvider()`
- L83–126: `inferFamily()`
- L128–137: `isCurrentModel()`
- L139–144: `aliasKey()`
- L146–158: `preferredModel()`
- L160–200: `parseModels()`
- L202–227: `prefetchModels()`
- L254–268: `inferProviderFromModel()`
- L270–273: `supportsReasoningEffort()`
- L275–278: `supportsThinking()`
- L280–283: `usesReasoningTokens()`
- L285–313: `getInternalModelId()`
- L315–414: `elizaConfig()`
- L416–425: `buildOpenAIProbeBody()`
- L427–521: `buildModelTestVariants()`

### Handlers (delete entirely):
- L524–559: `app.post('/api/models/test', ...)`

---

## Step 3: Replace /api/models handler (L229–251)

**Было:** читает `models.json` cache, проверяет `ELIZA_TOKEN`.

**Станет:**
```js
app.get('/api/models', async (req, res) => {
  const proxyUrl = process.env.ELIZA_PROXY_URL || 'http://localhost:3100';
  try {
    const r = await fetch(`${proxyUrl}/v1/models`);
    const data = await r.json();
    res.json(data);
  } catch (e) {
    res.status(502).json({ error: `eliza-proxy unavailable: ${e.message}` });
  }
});
```

---

## Step 4: Replace /api/chat handler (L563–675)

**Было:** `elizaConfig(model)` → выбор URL/формата → прямой fetch к `api.eliza.yandex.net` → нормализация Anthropic/OpenAI SSE.

**Станет:** простой SSE passthrough к eliza-proxy. Формат ответа (`data: {"text":"..."}` / `data: [DONE]`) уже совпадает — нормализация не нужна.

```js
app.post('/api/chat', async (req, res) => {
  const { model, messages, system } = req.body;
  const proxyUrl = process.env.ELIZA_PROXY_URL || 'http://localhost:3100';

  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  let clientConnected = true;
  res.on('close', () => { clientConnected = false; });
  const safeWrite = (data) => { if (clientConnected) res.write(data); };

  try {
    const upstream = await fetch(`${proxyUrl}/v1/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ model, messages, system }),
    });

    if (!upstream.ok) {
      safeWrite(`data: {"error":"eliza-proxy error: ${upstream.status}"}\n\n`);
      safeWrite('data: [DONE]\n\n');
      res.end();
      return;
    }

    const reader = upstream.body.getReader();
    const decoder = new TextDecoder();
    while (clientConnected) {
      const { done, value } = await reader.read();
      if (done) break;
      safeWrite(decoder.decode(value, { stream: true }));
    }
  } catch (e) {
    safeWrite(`data: {"error":"${e.message}"}\n\n`);
  }
  safeWrite('data: [DONE]\n\n');
  res.end();
});
```

---

## Step 5: Clean up startup block (L899–911)

Удалить:
- Предупреждение про `ELIZA_TOKEN` (lines ~903–908)
- Вызов `prefetchModels()` (line ~908)

Оставить: `app.listen(PORT, ...)` + лог старта.

---

## Step 6: Update .env.example

Удалить: `ELIZA_TOKEN`
Добавить: `ELIZA_PROXY_URL=http://localhost:3100`

---

## Files changed

| File | Action |
|------|--------|
| `server.js` | Restore from git, then modify |
| `lib/eliza-client/` | Delete directory |
| `scripts/test-models.js` | Delete |
| `models.json` | Delete |
| `.env.example` | Update |

## Files untouched

- `/api/execute` handler (L678–751)
- `/api/knowledge` handlers
- `/api/rules` handlers
- `public/index.html`
- `knowledge/`, `rules.json`

---

## Verification

1. Запустить eliza-proxy: `cd eliza-proxy && npm run dev`
2. Запустить groovy_agent: `cd groovy_agent && npm run dev`
3. Открыть `http://localhost:3000`
4. Проверить что список моделей загружается (из eliza-proxy)
5. Отправить сообщение — убедиться что стриминг работает
6. Выполнить Groovy скрипт — убедиться что execution не сломан

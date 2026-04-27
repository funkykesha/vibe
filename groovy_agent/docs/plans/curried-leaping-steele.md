# Plan: Переезд Eliza в standalone сервис `eliza-proxy`

## Context

`groovy_agent` — монолит: в нём Eliza-логика, Groovy UI, knowledge base. Команда genidea и другие клиенты хотят прямой доступ к LLM без зависимости от groovy_agent. Архитектурный план написан (`docs/eliza-proxy-architecture-plan.md`), `lib/eliza-client/` реализован (Tasks 1–7, 77 тестов). Tasks 8–10 в groovy_agent не выполнены. `eliza-proxy` как сервис не создан.

**Цель:** создать `/vibe/eliza-proxy/` — отдельный Express-сервис на порту 3100, переключить groovy_agent на него, переключить genidea на него.

---

## Текущее состояние

| Что | Статус |
|-----|--------|
| `lib/eliza-client/` (chat, probe, getModels, streaming, routing) | ✅ готово, 77 тестов |
| `docs/eliza-proxy-architecture-plan.md` — полный план с server.js | ✅ готово |
| `docs/eliza-client-integration-guide.md` — гайд для команд | ✅ готово |
| Task 8: wire eliza-client в server.js groovy_agent (~300 строк удалить) | ❌ не сделано |
| Task 9: упростить `scripts/test-models.js` до ~30 строк | ❌ не сделано |
| Task 10: `public/index.html` — fix `data.pending` → `!data.validated` | ❌ не сделано |
| `eliza-proxy` сервис | ❌ не создан |

---

## Шаги

### Шаг 1: Создать `/vibe/eliza-proxy/`

Новый проект — **не трогать groovy_agent**.

**Файлы:**
```
/vibe/eliza-proxy/
  server.js          ← взять из docs/eliza-proxy-architecture-plan.md §1.5 (готовый код)
  package.json       ← express, cors, dotenv (из §1.2)
  .env.example       ← ELIZA_TOKEN, PORT=3100, LOG_USAGE=true, USAGE_LOG_FILE=./usage.jsonl
  lib/
    eliza-client/    ← скопировать groovy_agent/lib/eliza-client/ as-is
  CLAUDE.md          ← взять из docs/eliza-proxy-architecture-plan.md §1.6
```

**Ключевые файлы источника:**
- `groovy_agent/lib/eliza-client/index.js` — клиент
- `groovy_agent/lib/eliza-client/routing.js` — роутинг провайдеров
- `groovy_agent/lib/eliza-client/streaming.js` — нормализация SSE
- `groovy_agent/lib/eliza-client/probe.js` — probe
- `groovy_agent/lib/eliza-client/models.js` — парсинг моделей

Скопировать вместе с `lib/eliza-client/test/` — запускать `node --test lib/eliza-client/test` в eliza-proxy.

**Проверка Шага 1:**
```bash
cd /vibe/eliza-proxy && npm install && node server.js
curl http://localhost:3100/v1/health
# → {"status":"ok","version":"1.0.0","modelsValidated":false}

curl http://localhost:3100/v1/models
# → {"models":[...], "validated":true}

curl -N -X POST localhost:3100/v1/chat \
  -H 'Content-Type: application/json' \
  -d '{"model":"claude-haiku-4-5","messages":[{"role":"user","content":"1+1=?"}]}'
# → data: {"text":"..."} ... data: {"usage":{...}} ... data: [DONE]
```

---

### Шаг 2: Task 8 — wire eliza-client в `groovy_agent/server.js`

**Цель:** удалить ~300 строк inline Eliza-логики из server.js, заменить на `createElizaClient`.

**Что удалить** из `server.js`:
- inline `elizaConfig()` / `buildRequest()` / провайдер-роутинг
- inline SSE нормализацию (Anthropic/OpenAI → unified format)
- inline `fetchModels()` / `parseModels()` / `preferredModel()` / дедупликацию
- inline `prefetchModels()` / логику запуска `scripts/test-models.js` как subprocess

**Что добавить:**
```javascript
const { createElizaClient } = require('./lib/eliza-client');
const ELIZA_TOKEN = process.env.ELIZA_TOKEN;
const eliza = ELIZA_TOKEN ? createElizaClient({ token: ELIZA_TOKEN }) : null;
```

**Также добавить `createProxyClient`** (из `docs/eliza-proxy-architecture-plan.md` §2.2) для поддержки `ELIZA_PROXY_URL`:
```javascript
const ELIZA_PROXY_URL = process.env.ELIZA_PROXY_URL;
const eliza = ELIZA_PROXY_URL
  ? createProxyClient(ELIZA_PROXY_URL)
  : (ELIZA_TOKEN ? createElizaClient({ token: ELIZA_TOKEN }) : null);
```

**Не трогать:**
- `buildSystemPrompt()`, `loadKnowledge()`, `loadRules()`
- `/api/execute` (Groovy subprocess)
- `/api/knowledge/*`, `/api/rules`
- `public/index.html` (до Task 10)

**Проверка Шага 2:**
```bash
# С прямым токеном
ELIZA_TOKEN=xxx node server.js
# → /api/models возвращает модели, /api/chat работает

# Через прокси
ELIZA_PROXY_URL=http://localhost:3100 node server.js
# → /api/models прокидывает запрос на 3100, чат работает
```

---

### Шаг 3: Task 9 — упростить `scripts/test-models.js`

После Task 8 `test-models.js` больше не нужен как standalone — probe встроен в `eliza-client`. Упростить до ~30-строк CLI-wrapper:

```javascript
const { createElizaClient } = require('../lib/eliza-client');
const eliza = createElizaClient({ token: process.env.ELIZA_TOKEN });
eliza.getModels().then(({ onValidated }) => {
  onValidated(models => {
    console.log(JSON.stringify(models, null, 2));
    process.exit(0);
  });
});
```

---

### Шаг 4: Task 10 — fix `public/index.html`

Файл: `groovy_agent/public/index.html`

Найти и заменить `data.pending` логику на `!data.validated`:
```javascript
// Было
if (data.pending) { ... }

// Стало
if (!data.validated) { ... }
```

---

### Шаг 5: Переключить `genidea` на `eliza-proxy`

Файл: `genidea/index.html`

```javascript
// Было
const AGENT_BASE_URL = 'http://localhost:3000';
// путь: /api/chat
// body: { model, system, messages, currentCode, inputData }

// Стало
const AGENT_BASE_URL = 'http://localhost:3100';
// путь: /v1/chat
// body: { model, system, messages }  ← убрать currentCode, inputData
```

Добавить обработку `usage` в SSE-парсере genidea:
```javascript
const msg = JSON.parse(payload);
if (msg.error) throw new Error(msg.error);
if (msg.usage) onUsage?.(msg.usage);   // опционально: показать cost
if (msg.text)  result += msg.text;
```

**Проверка Шага 5:**
- Flow A (генерация промпта) работает через eliza-proxy на 3100
- Usage появляется в `/vibe/eliza-proxy/usage.jsonl`

---

## Риски

| Риск | Митигация |
|------|-----------|
| `lib/eliza-client/` расходится между проектами | groovy_agent — источник истины; изменения синхронизировать вручную. В будущем: npm-пакет или git submodule |
| eliza-proxy падает → groovy_agent не работает | fallback: если `ELIZA_PROXY_URL` не задан, groovy_agent работает напрямую через `ELIZA_TOKEN` |
| PORT конфликт | groovy_agent: 3000, eliza-proxy: 3100 — не пересекаются |
| usage не точен (Anthropic может не слать input_tokens в стриме) | логировать `?? 0`, добавить предупреждение в /v1/health |

---

## Порядок выполнения

```
Шаг 1: создать eliza-proxy          ← независимо, нужен первым
Шаг 2: Task 8 (server.js)           ← после Шага 1 (нужен ELIZA_PROXY_URL работающий)
Шаг 3: Task 9 (test-models.js)      ← после Шага 2
Шаг 4: Task 10 (index.html fix)     ← параллельно Шагу 2/3
Шаг 5: genidea switch               ← последним, когда eliza-proxy проверен
```

---

## Ключевые файлы

| Файл | Роль |
|------|------|
| `docs/eliza-proxy-architecture-plan.md` | Полный план с готовым кодом server.js §1.5, createProxyClient §2.2 |
| `lib/eliza-client/index.js` | Источник истины клиента — копировать в eliza-proxy |
| `lib/eliza-client/routing.js` | Роутинг провайдеров |
| `lib/eliza-client/streaming.js` | SSE нормализация |
| `server.js` | Менять: Tasks 8 (wire eliza-client + createProxyClient) |
| `public/index.html` | Менять: Task 10 (pending → validated) |
| `genidea/index.html` | Менять: Шаг 5 (base URL + path) |

---

## Проверка end-to-end

```bash
# 1. eliza-proxy работает
curl http://localhost:3100/v1/health  # → {"status":"ok"}

# 2. groovy_agent через прокси
ELIZA_PROXY_URL=http://localhost:3100 npm run dev
curl http://localhost:3000/api/models  # → те же модели

# 3. groovy_agent напрямую (fallback)
ELIZA_TOKEN=xxx npm run dev  # без ELIZA_PROXY_URL
curl http://localhost:3000/api/models  # → работает

# 4. genidea
open http://localhost:8080  # или как запускается genidea
# → Flow A генерирует промпт через localhost:3100

# 5. usage лог
tail -f /vibe/eliza-proxy/usage.jsonl  # → записи после каждого чата
```

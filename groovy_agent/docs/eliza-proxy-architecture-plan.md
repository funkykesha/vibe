# Plan: eliza-proxy — Standalone Eliza API Service

See also: `docs/eliza-client-integration-guide.md` for current (`as-is`) and target (`to-be`) integration contracts.

**Дата:** 2026-04-26  
**Статус:** PLAN (не реализовано)  
**Исполнитель:** внешняя команда  
**Ревьюер:** @yamac

---

## Контекст и мотивация

Сейчас Eliza API доступен только через `groovy_agent` — монолитный Express-сервер для Groovy-разработки. Команда genidea и другие клиенты хотят:

- Напрямую обращаться к LLM без зависимости от groovy_agent
- Получать usage/cost в SSE-стриме
- Иметь стабильный, версионированный API

**Решение:** вынести Eliza-логику в отдельный сервис `eliza-proxy`.

### До (текущее)

```
genidea ──────→ groovy_agent ──OAuth──→ Eliza API
                  (port 3000)           (api.eliza.yandex.net)
groovy_agent ─→ groovy_agent
(Groovy UI)
```

### После

```
genidea ──────→ eliza-proxy ──OAuth──→ Eliza API
                (port 3100)            (api.eliza.yandex.net)
groovy_agent ─→ eliza-proxy
(Groovy UI)       (port 3100)
```

---

## Часть 1: Новый сервис `eliza-proxy`

### 1.1 Расположение

Создать директорию `/vibe/eliza-proxy/` как **отдельный проект**.

```
eliza-proxy/
  server.js          ← точка входа, Express
  package.json
  .env.example
  lib/
    eliza-client/    ← COPY или symlink из groovy_agent/lib/eliza-client/
  CLAUDE.md          ← инструкции для AI-агентов
```

> **Важно:** `lib/eliza-client/` уже реализован в `groovy_agent/lib/eliza-client/` (Tasks 1–7, 77 тестов). Скопировать as-is.

### 1.2 Зависимости

```json
{
  "name": "eliza-proxy",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.0",
    "cors": "^2.8.5",
    "dotenv": "^16.0.0"
  }
}
```

Нет новых зависимостей сверх уже используемых в groovy_agent.

### 1.3 Переменные окружения

```env
# .env
ELIZA_TOKEN=<OAuth-токен>    # обязателен
PORT=3100                    # порт сервиса (default: 3100)
LOG_USAGE=true               # писать usage в файл (default: true)
USAGE_LOG_FILE=./usage.jsonl # путь к лог-файлу
```

**Получение токена:**  
`https://oauth.yandex-team.ru/authorize?response_type=token&client_id=60c90ec3a2b846bcbf525b0b46baac80`

### 1.4 API

#### `GET /v1/health`

```json
{ "status": "ok", "version": "1.0.0", "modelsValidated": true }
```

#### `GET /v1/models`

```json
{
  "models": [
    {
      "id": "claude-sonnet-4-6",
      "title": "Claude Sonnet 4.6",
      "provider": "anthropic",
      "family": "claude-sonnet",
      "prices": {
        "input_tokens": "0.000003",
        "output_tokens": "0.000015",
        "input_cache_read_tokens": "0.0000003"
      },
      "probe": {
        "checkedAt": "2026-04-26T10:00:00Z",
        "status": 200,
        "sample": "Hello! How can I help you?"
      }
    }
  ],
  "validated": true,
  "updatedAt": "2026-04-26T10:00:00Z"
}
```

#### `POST /v1/chat` → SSE

**Request:**

```json
{
  "model": "claude-sonnet-4-6",
  "messages": [
    { "role": "user", "content": "Привет" }
  ],
  "system": "Ты полезный ассистент."
}
```

**Response** (SSE, `Content-Type: text/event-stream`):

```
data: {"text":"Привет"}\n\n
data: {"text":"! Чем могу помочь?"}\n\n
data: {"usage":{"input":12,"output":8,"model":"claude-sonnet-4-6","cost_usd":0.000156}}\n\n
data: [DONE]\n\n
```

**При ошибке:**

```
data: {"error":"описание ошибки"}\n\n
```

**Поля запроса:**


| Поле       | Тип    | Обязателен | Описание                  |
| ---------- | ------ | ---------- | ------------------------- |
| `model`    | string | да         | ID модели из `/v1/models` |
| `messages` | array  | да         | `[{ role: "user"          |
| `system`   | string | нет        | системный промпт          |


**Особенности роутинга (обрабатывает прокси автоматически):**

- Claude → Anthropic API format, endpoint `/raw/anthropic/v1/messages`
- GPT-4o, Gemini, DeepSeek, Grok → OpenRouter, endpoint `/raw/openrouter/v1/chat/completions`
- GPT-4.1, o1/o3/o4 → OpenAI format, endpoint `/raw/openai/v1/chat/completions`
- Internal (GLM, GPT-OSS, Alice, Qwen3-coder, Minimax) → internal endpoints
- GPT-5: вернуть HTTP 501 (не поддерживает SSE)
- o1/o3/o4/grok (reasoning): role `developer` вместо `system`, без `temperature`

#### `POST /v1/probe`

**Request:** `{ "model": "gpt-4.1" }`  
**Response:** `{ "available": true, "latency": 1240 }`

#### `GET /v1/usage`

Агрегированная статистика с последнего рестарта сервиса (или из JSONL файла):

```json
{
  "total_requests": 142,
  "total_input_tokens": 840200,
  "total_output_tokens": 124300,
  "total_cost_usd": 3.47,
  "by_model": {
    "claude-sonnet-4-6": {
      "requests": 80,
      "input_tokens": 500000,
      "output_tokens": 80000,
      "cost_usd": 2.70
    }
  },
  "period_start": "2026-04-26T00:00:00Z",
  "generated_at": "2026-04-26T14:32:00Z"
}
```

### 1.5 Реализация server.js

```javascript
'use strict';
require('dotenv').config();

const express = require('express');
const cors    = require('cors');
const fs      = require('fs');
const { createElizaClient, ElizaError } = require('./lib/eliza-client');

const ELIZA_TOKEN    = process.env.ELIZA_TOKEN;
const PORT           = process.env.PORT || 3100;
const USAGE_LOG_FILE = process.env.USAGE_LOG_FILE || './usage.jsonl';
const LOG_USAGE      = process.env.LOG_USAGE !== 'false';

if (!ELIZA_TOKEN) {
  console.error('FATAL: ELIZA_TOKEN не задан в .env');
  process.exit(1);
}

const eliza = createElizaClient({ token: ELIZA_TOKEN });

// In-memory usage aggregation
const usageStats = {
  total_requests: 0,
  total_input_tokens: 0,
  total_output_tokens: 0,
  total_cost_usd: 0,
  by_model: {},
  period_start: new Date().toISOString(),
};

function recordUsage(model, input, output, prices) {
  const input_price  = parseFloat(prices?.input_tokens  || 0);
  const output_price = parseFloat(prices?.output_tokens || 0);
  const cost = (input * input_price) + (output * output_price);

  usageStats.total_requests      += 1;
  usageStats.total_input_tokens  += input;
  usageStats.total_output_tokens += output;
  usageStats.total_cost_usd      += cost;

  if (!usageStats.by_model[model]) {
    usageStats.by_model[model] = { requests: 0, input_tokens: 0, output_tokens: 0, cost_usd: 0 };
  }
  usageStats.by_model[model].requests      += 1;
  usageStats.by_model[model].input_tokens  += input;
  usageStats.by_model[model].output_tokens += output;
  usageStats.by_model[model].cost_usd      += cost;

  if (LOG_USAGE) {
    const entry = JSON.stringify({ ts: new Date().toISOString(), model, input, output, cost_usd: cost });
    fs.appendFile(USAGE_LOG_FILE, entry + '\n', () => {});
  }

  return cost;
}

const app = express();
app.use(cors({ origin: '*' }));   // для прода сузить до known origins
app.use(express.json());

// ── Health ──────────────────────────────────────────────────────────────────

app.get('/v1/health', async (req, res) => {
  try {
    const { validated } = await eliza.getModels();
    res.json({ status: 'ok', version: '1.0.0', modelsValidated: validated });
  } catch (err) {
    res.status(503).json({ status: 'error', error: err.message });
  }
});

// ── Models ──────────────────────────────────────────────────────────────────

app.get('/v1/models', async (req, res) => {
  try {
    const { models, validated } = await eliza.getModels();
    res.json({ models, validated, updatedAt: new Date().toISOString() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Chat — SSE streaming ────────────────────────────────────────────────────

app.post('/v1/chat', async (req, res) => {
  const { model, messages, system } = req.body;

  if (!model || !Array.isArray(messages)) {
    res.status(400).json({ error: 'model and messages required' });
    return;
  }

  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  let clientConnected = true;
  res.on('close',  () => { clientConnected = false; });
  res.on('error',  () => { clientConnected = false; });

  function safeWrite(data) {
    if (!clientConnected || res.destroyed || res.writableEnded) return false;
    try { res.write(data); return true; } catch { clientConnected = false; return false; }
  }

  try {
    // Lookup prices for this model
    const { models } = await eliza.getModels();
    const modelMeta = models.find(m => m.id === model);
    const prices = modelMeta?.prices || {};

    let usageInput = 0, usageOutput = 0;

    for await (const { delta, done, usage, error } of eliza.chat(model, messages, { system })) {
      if (!clientConnected) break;

      if (error) {
        safeWrite(`data: ${JSON.stringify({ error })}\n\n`);
        break;
      }

      if (usage) {
        usageInput  = usage.input  ?? usageInput;
        usageOutput = usage.output ?? usageOutput;
      }

      if (done) {
        const cost_usd = recordUsage(model, usageInput, usageOutput, prices);
        if (usageInput || usageOutput) {
          safeWrite(`data: ${JSON.stringify({ usage: { input: usageInput, output: usageOutput, model, cost_usd } })}\n\n`);
        }
        safeWrite('data: [DONE]\n\n');
        break;
      }

      if (delta) {
        safeWrite(`data: ${JSON.stringify({ text: delta })}\n\n`);
      }
    }
  } catch (err) {
    if (err instanceof ElizaError && err.status === 429) {
      // Rate limit — pass through to client
      safeWrite(`data: ${JSON.stringify({ error: 'Rate limit exceeded', retry_after: null })}\n\n`);
    } else if (err instanceof ElizaError && err.status === 501) {
      safeWrite(`data: ${JSON.stringify({ error: `Model ${model} does not support streaming` })}\n\n`);
    } else {
      safeWrite(`data: ${JSON.stringify({ error: err.message })}\n\n`);
    }
  } finally {
    if (!res.writableEnded) try { res.end(); } catch { /* closed */ }
  }
});

// ── Probe ───────────────────────────────────────────────────────────────────

app.post('/v1/probe', async (req, res) => {
  const { model } = req.body;
  if (!model) { res.status(400).json({ error: 'model required' }); return; }
  const t0 = Date.now();
  const available = await eliza.probe(model);
  res.json({ available, latency: Date.now() - t0 });
});

// ── Usage stats ─────────────────────────────────────────────────────────────

app.get('/v1/usage', (req, res) => {
  res.json({ ...usageStats, generated_at: new Date().toISOString() });
});

// ── Start ───────────────────────────────────────────────────────────────────

app.listen(PORT, () => {
  console.log(`eliza-proxy: http://localhost:${PORT}`);
  console.log(`ELIZA_TOKEN: OK`);
});
```

### 1.6 CLAUDE.md для команды

Создать `eliza-proxy/CLAUDE.md`:

```markdown
# eliza-proxy

Standalone HTTP proxy к Yandex Eliza API. Добавляет OAuth auth, роутинг по провайдерам, нормализацию SSE, usage/cost tracking.

## Запуск
npm install && npm start   # PORT=3100

## Зависимости
ELIZA_TOKEN в .env — обязателен.

## Ключевые файлы
- server.js — Express, все endpoints
- lib/eliza-client/ — логика работы с Eliza (скопировано из groovy_agent)

## Тесты
node --test lib/eliza-client/test   # 77 тестов

## API
GET  /v1/health   — healthcheck
GET  /v1/models   — список моделей с prices
POST /v1/chat     — SSE стриминг
POST /v1/probe    — проверка доступности модели
GET  /v1/usage    — агрегированная статистика

## Не менять без согласования
- lib/eliza-client/ — общий модуль, любые изменения влияют на groovy_agent
- SSE формат /v1/chat — клиенты зависят от формата
```

---

## Часть 2: Адаптация groovy_agent

**Принцип: минимальные изменения.** groovy_agent продолжает работать как раньше, просто делегирует Eliza-вызовы в eliza-proxy.

### 2.1 Новая переменная окружения

```env
# .env в groovy_agent
ELIZA_PROXY_URL=http://localhost:3100   # URL eliza-proxy
# ELIZA_TOKEN больше не нужен для LLM-вызовов
```

Обратная совместимость: если `ELIZA_PROXY_URL` не задан — fallback на прямые вызовы через `ELIZA_TOKEN` (старое поведение).

### 2.2 Изменения в server.js

**Заменить инициализацию eliza-client:**

```javascript
// Было
const eliza = ELIZA_TOKEN ? createElizaClient({ token: ELIZA_TOKEN }) : null;

// Стало
const ELIZA_PROXY_URL = process.env.ELIZA_PROXY_URL;
const eliza = ELIZA_PROXY_URL
  ? createProxyClient(ELIZA_PROXY_URL)
  : (ELIZA_TOKEN ? createElizaClient({ token: ELIZA_TOKEN }) : null);
```

**Реализация `createProxyClient(baseUrl)` — thin wrapper:**

```javascript
function createProxyClient(baseUrl) {
  return {
    async getModels() {
      const res = await fetch(`${baseUrl}/v1/models`);
      if (!res.ok) throw new Error(`proxy models error: ${res.status}`);
      return res.json();   // { models, validated }
    },

    async* chat(model, messages, { system } = {}) {
      const res = await fetch(`${baseUrl}/v1/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model, messages, system }),
      });
      if (!res.ok) throw new Error(`proxy chat error: ${res.status}`);

      const reader  = res.body.getReader();
      const decoder = new TextDecoder();
      let buf = '';

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buf += decoder.decode(value, { stream: true });
        const lines = buf.split('\n');
        buf = lines.pop();
        for (const line of lines) {
          if (!line.startsWith('data: ')) continue;
          const raw = line.slice(6).trim();
          if (raw === '[DONE]') { yield { delta: '', done: true }; return; }
          const obj = JSON.parse(raw);
          if (obj.error)  yield { delta: '', done: true, error: obj.error };
          if (obj.text)   yield { delta: obj.text, done: false };
          if (obj.usage)  yield { delta: '', done: false, usage: obj.usage };
        }
      }
    },

    async probe(model) {
      const res = await fetch(`${baseUrl}/v1/probe`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model }),
      });
      if (!res.ok) return false;
      const { available } = await res.json();
      return available;
    },
  };
}
```

**Остальные endpoint handlers** (`/api/chat`, `/api/models`) — **без изменений**. `eliza.chat()` / `eliza.getModels()` / `eliza.probe()` вызываются через тот же интерфейс.

### 2.3 Что НЕ меняется в groovy_agent

- `buildSystemPrompt()` — groovy-специфический промпт
- `loadKnowledge()` / `loadRules()` — knowledge base
- `/api/execute` — выполнение Groovy
- `/api/knowledge/`*, `/api/rules` — управление базой знаний
- `public/index.html` — фронтенд groovy_agent
- Все тесты

---

## Часть 3: Адаптация genidea

После запуска eliza-proxy:

**Изменить в `genidea/index.html`:**

```javascript
// Было
const AGENT_BASE_URL = 'http://localhost:3000';
// ...
body: JSON.stringify({
  model, system: systemPrompt,
  messages: [{ role: 'user', content: userMessage }],
  currentCode: '', inputData: '{}',
}),

// Стало
const AGENT_BASE_URL = 'http://localhost:3100';
// ...
body: JSON.stringify({
  model, system: systemPrompt,
  messages: [{ role: 'user', content: userMessage }],
  // currentCode и inputData больше не нужны
}),
```

**Добавить обработку usage:**

```javascript
const msg = JSON.parse(payload);
if (msg.error)  throw new Error(msg.error);
if (msg.usage)  onUsage?.(msg.usage);   // callback для аналитики
if (msg.text)   result += msg.text;
```

---

## Часть 4: Порядок выполнения

```
[Шаг 1] Создать eliza-proxy/ с server.js и скопированным lib/eliza-client/
         Проверить: npm start → GET /v1/health → {"status":"ok"}

[Шаг 2] Протестировать /v1/models — должны вернуться модели с prices

[Шаг 3] Протестировать /v1/chat:
         curl -N -X POST localhost:3100/v1/chat \
           -H 'Content-Type: application/json' \
           -d '{"model":"claude-haiku-4-5","messages":[{"role":"user","content":"1+1=?"}]}'
         Ожидать: data: {"text":"..."} ... data: {"usage":{...}} ... data: [DONE]

[Шаг 4] Настроить groovy_agent: ELIZA_PROXY_URL=http://localhost:3100
         Проверить: groovy_agent /api/models → те же модели
         Проверить: groovy_agent чат → работает через прокси

[Шаг 5] Обновить genidea: AGENT_BASE_URL → localhost:3100, путь → /v1/chat
         Проверить: Flow A (генерация промпта) работает

[Шаг 6] Smoke test всех трёх сервисов одновременно
```

---

## Часть 5: Риски и митигации


| Риск                                                                    | Вероятность | Митигация                                       |
| ----------------------------------------------------------------------- | ----------- | ----------------------------------------------- |
| eliza-proxy падает → groovy_agent не работает                           | Средняя     | fallback на прямой ELIZA_TOKEN в groovy_agent   |
| lib/eliza-client расходится между проектами                             | Высокая     | вынести в отдельный npm-пакет или git submodule |
| usage данные не точные (Anthropic не всегда шлёт input_tokens в стриме) | Средняя     | логировать `?? 0`, предупредить genidea         |
| ELIZA_TOKEN истёк                                                       | Средняя     | /v1/health вернёт ошибку; настроить алерт       |
| PORT конфликт с groovy_agent                                            | Низкая      | использовать порт 3100 (groovy_agent на 3000)   |


---

## Часть 6: Чеклист для команды-исполнителя

- Создать `/vibe/eliza-proxy/` с файлами из этого плана
- Скопировать `groovy_agent/lib/eliza-client/` в `eliza-proxy/lib/eliza-client/`
- `npm install` → `npm start` → `GET /v1/health` возвращает `{"status":"ok"}`
- `GET /v1/models` возвращает ≥10 моделей с полем `prices`
- `POST /v1/chat` с `claude-haiku-4-5` возвращает SSE с `{"usage":{...}}` перед `[DONE]`
- `POST /v1/probe` с `claude-haiku-4-5` возвращает `{"available":true}`
- `GET /v1/usage` возвращает статистику после chat-запросов
- groovy_agent с `ELIZA_PROXY_URL=http://localhost:3100` работает полностью
- groovy_agent с `ELIZA_TOKEN` (без `ELIZA_PROXY_URL`) работает как раньше
- genidea с `AGENT_BASE_URL=http://localhost:3100` генерирует промпты
- В `usage.jsonl` появляются записи после каждого chat-запроса

---

## Связанные файлы


| Файл                                                                    | Назначение                                               |
| ----------------------------------------------------------------------- | -------------------------------------------------------- |
| `groovy_agent/lib/eliza-client/index.js`                                | Публичное API клиента (chat, chatOnce, probe, getModels) |
| `groovy_agent/lib/eliza-client/routing.js`                              | Роутинг по провайдерам, elizaConfig()                    |
| `groovy_agent/lib/eliza-client/streaming.js`                            | Нормализация SSE → { delta, done, usage }                |
| `groovy_agent/lib/eliza-client/probe.js`                                | Проверка доступности моделей                             |
| `groovy_agent/lib/eliza-client/models.js`                               | Парсинг и фильтрация списка моделей                      |
| `genidea/eliza-api-answers.md`                                          | Ответы на вопросы команды genidea                        |
| `groovy_agent/docs/superpowers/specs/2026-04-19-eliza-client-design.md` | Спека eliza-client                                       |



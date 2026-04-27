# ТЗ: Миграция genidea на eliza-proxy

**Дата:** 2026-04-27  
**Исполнитель:** команда genidea  
**Ревьюер:** @yamac

---

## Контекст

Eliza-логика вынесена из `groovy_agent` в отдельный сервис `eliza-proxy` (порт 3100).  
`genidea` сейчас обращается к `groovy_agent` на порт 3000 — нужно переключить на `eliza-proxy`.

**Что даёт переход:**
- Прямой доступ к LLM, независимость от groovy_agent
- usage/cost в SSE-стриме (`{"usage":{...}}` перед `[DONE]`)
- Стабильный `/v1/*` API

---

## Что нужно изменить

Все изменения — в одном файле: `genidea/index.html`.

### 1. Base URL и путь чата

**Строка ~106:**
```javascript
// Было
const AGENT_BASE_URL = 'http://localhost:3000';

// Стало
const AGENT_BASE_URL = 'http://localhost:3100';
```

**Строка ~165:**
```javascript
// Было
const response = await fetch(`${AGENT_BASE_URL}/api/chat`, {

// Стало
const response = await fetch(`${AGENT_BASE_URL}/v1/chat`, {
```

### 2. Тело запроса — убрать лишние поля

**Строки ~168–174:**
```javascript
// Было
body: JSON.stringify({
  model,
  system: systemPrompt,
  messages: [{ role: 'user', content: userMessage }],
  currentCode: '',
  inputData: '{}',
}),

// Стало
body: JSON.stringify({
  model,
  system: systemPrompt,
  messages: [{ role: 'user', content: userMessage }],
}),
```

`currentCode` и `inputData` — поля groovy_agent, eliza-proxy их не принимает.

### 3. SSE-парсер — добавить обработку usage

**Строки ~191–196:**
```javascript
// Было
const msg = JSON.parse(payload);
if (msg.error) throw new Error(msg.error);
if (msg.text) result += msg.text;

// Стало
const msg = JSON.parse(payload);
if (msg.error) throw new Error(msg.error);
if (msg.usage) { /* опционально: console.log('cost:', msg.usage.cost_usd) */ }
if (msg.text) result += msg.text;
```

`msg.usage` приходит один раз перед `[DONE]`:
```json
{"usage": {"input": 120, "output": 85, "model": "claude-sonnet-4-6", "cost_usd": 0.00031}}
```

Если не нужна аналитика — строку `if (msg.usage)` можно не добавлять, она не ломает логику.

### 4. Список моделей

**Строка ~966:**
```javascript
// Было
fetch(`${AGENT_BASE_URL}/api/models`)

// Стало (автоматически после п.1 — base URL уже изменён)
fetch(`${AGENT_BASE_URL}/v1/models`)
```

**Строка ~969 — fix проверки pending:**
```javascript
// Было
if (data.models && data.models.length > 0 && !data.pending) {

// Стало
if (data.models && data.models.length > 0 && data.validated) {
```

---

## Предусловие

Перед тестированием запустить eliza-proxy:

```bash
cd /vibe/eliza-proxy
# убедиться что .env есть с ELIZA_TOKEN
npm start
# → eliza-proxy: http://localhost:3100
```

---

## Проверка

```bash
# 1. eliza-proxy жив
curl http://localhost:3100/v1/health
# → {"status":"ok","version":"1.0.0","modelsValidated":...}

# 2. Модели отдаются
curl http://localhost:3100/v1/models | head -5

# 3. Чат работает
curl -N -X POST http://localhost:3100/v1/chat \
  -H 'Content-Type: application/json' \
  -d '{"model":"claude-haiku-4-5","messages":[{"role":"user","content":"1+1=?"}]}'
# Ожидать: data: {"text":"2"} ... data: {"usage":{...}} ... data: [DONE]
```

После изменений в genidea:
- Открыть genidea в браузере
- Flow A (генерация промпта) должен работать
- В DevTools → Network убедиться что запрос идёт на `localhost:3100/v1/chat`

---

## Контракт SSE /v1/chat

```
data: {"text":"..."}\n\n       ← чанки текста
data: {"usage":{...}}\n\n      ← один раз перед DONE
data: [DONE]\n\n               ← конец стрима
data: {"error":"..."}\n\n      ← при ошибке
```

Формат **идентичен** текущему `/api/chat` — парсер менять не нужно, только добавить опциональный `msg.usage`.

---

## Итого: 4 строки изменений

| Файл | Строка | Что |
|------|--------|-----|
| `index.html` | ~106 | `3000` → `3100` |
| `index.html` | ~165 | `/api/chat` → `/v1/chat` |
| `index.html` | ~172–173 | удалить `currentCode` и `inputData` |
| `index.html` | ~966 | `/api/models` → `/v1/models` (или само после п.1) |
| `index.html` | ~969 | `!data.pending` → `data.validated` |

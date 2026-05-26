# Plan: Open Design integration — финальная верификация и 429 retry

## Context

Реализация `/v1/chat/completions` завершена (`prancy-wondering-toucan.md`). eliza-proxy полностью готов к работе с Open Design:
- `POST /v1/chat/completions` (stream + non-stream) — реализован в server.js:370-479
- `GET /v1/models` (OpenAI list format) — server.js:286-297
- CORS `origin: '*'` — server.js:225
- Authorization header игнорируется, токен из env

Осталось две вещи: верифицировать интеграцию с Open Design и реализовать 429 retry из `jaunty-singing-sprout.md`.

## Задача 1: Верификация endpoint

**Нет кода — только ручная проверка.**

```bash
# 1. Запустить proxy
npm start

# 2. Проверить models endpoint
curl http://localhost:3100/v1/models | jq '.data[].id' | head -5

# 3. Stream проверка
curl -N -X POST http://localhost:3100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test" \
  -d '{"model":"deepseek-v3-2","messages":[{"role":"user","content":"hi"}],"stream":true}'
# Ожидать: SSE chunks choices[0].delta.content, финальный finish_reason:"stop", затем [DONE]

# 4. Non-stream проверка
curl -X POST http://localhost:3100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"deepseek-v3-2","messages":[{"role":"user","content":"hi"}],"stream":false}'
# Ожидать: JSON {choices:[{message:{content:"..."}}]}
```

## Задача 2: Конфигурация Open Design

Open Design BYOK mode (Settings → Provider → OpenAI-compatible):
```
baseUrl: http://localhost:3100
apiKey:  eliza  (любая непустая строка)
model:   deepseek-v3-2  (или другая из /v1/models)
```

Альтернатива через env при запуске Open Design daemon:
```bash
OPENAI_API_BASE=http://localhost:3100/v1 OPENAI_API_KEY=eliza npm run daemon
```

**Потенциальные проблемы:**
- Open Design шлёт стандартный model ID (`gpt-4o`, `claude-3-5-sonnet-20241022`) → eliza routing не знает этот ID → упадёт с ошибкой или уйдёт на дефолтный endpoint. Фикс: использовать eliza-style ID из `/v1/models`.
- Модель `deepseek-v3-2` работает через `/raw/openai/...` (дефолтный роутинг) — безопасный выбор для первого теста.

## Задача 3: 429 retry в `chat()` — реализация jaunty плана

**Файлы:** `lib/eliza-client/index.js`

**Логика:**
1. Обернуть `fetch()` в retry loop: max 2 retries (итого 3 попытки)
2. При 429: проверить `Retry-After` header → если есть, sleep на указанное время; иначе backoff [1000ms, 2000ms]
3. После 3 неудачных попыток — бросить `ElizaError(429)`

**Место вставки:** `lib/eliza-client/index.js` в функции `fetchWithRetry` (или создать её рядом с существующей логикой `fetch`)

**Тесты:** добавить в `lib/eliza-client/test/` — сценарии:
- 429 → retry → success
- 429 → 429 → 429 → throw ElizaError
- 429 с `Retry-After: 2` → sleep 2000ms → retry

**Синхронизация:** после реализации скопировать `lib/eliza-client/index.js` в `../groovy_agent/lib/eliza-client/index.js`.

## Критические файлы

- `lib/eliza-client/index.js` — retry логика (задача 3)
- `lib/eliza-client/test/` — новые тесты для retry
- `server.js` — не трогать, всё уже реализовано

## Верификация после retry

```bash
npm test  # все 77 тестов + новые retry тесты
```

## Порядок работы

1. Запустить ручную верификацию `/v1/chat/completions` (задача 1) — убедиться что endpoint работает
2. Подключить Open Design (задача 2) — проверить e2e поток
3. Реализовать 429 retry в index.js (задача 3) — добавить тесты
4. Синхронизировать с groovy_agent
5. Архивировать `prancy-wondering-toucan.md` и `opendesign-adaptive-hare.md`

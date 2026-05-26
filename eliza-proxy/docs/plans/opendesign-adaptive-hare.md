# Open Design → eliza-proxy integration

## Context

Open Design (nexu-io/open-design) — Claude Design-аналог, умеет работать с любым OpenAI-compatible бэкендом через proxy mode. Локальная Eliza (api.eliza.yandex.net) недоступна напрямую из Open Design — нет нужных эндпоинтов или CORS. eliza-proxy уже экспозирует полностью совместимый `/v1/chat/completions` на порту 3100, но Open Design об этом не знает.

Цель: сконфигурировать Open Design использовать `http://localhost:3100` как OpenAI-compatible upstream.

## Что уже есть

eliza-proxy уже покрывает всё нужное Open Design:

| Эндпоинт | Статус |
|---|---|
| `POST /v1/chat/completions` (stream + non-stream) | ✅ |
| `GET /v1/models` (OpenAI list format) | ✅ |
| `GET /v1/health` | ✅ |
| CORS `origin: '*'` | ✅ |

Open Design не требует auth на upstream — передаёт `Authorization: Bearer <key>`, eliza-proxy его игнорирует (берёт token из env). Проблем нет.

## Что нужно сделать

### 1. Проверить формат `/v1/models`

Open Design читает `GET /v1/models` при выборе провайдера. Текущий ответ:
```json
{
  "object": "list",
  "data": [{ "id": "...", "object": "model", "created": 123, "owned_by": "eliza" }]
}
```
Это стандартный OpenAI формат — должно работать.

### 2. Настроить Open Design

Open Design daemon читает конфиг из переменных среды и/или UI. Нужно выбрать OpenAI-compatible провайдер с:
- `baseUrl`: `http://localhost:3100`  
- `apiKey`: `eliza` (любая непустая строка — eliza-proxy игнорирует)
- Модель: любая из `GET /v1/models` (например `claude-sonnet-4-6`)

Через env (в `.env` Open Design или при запуске):
```bash
OPENAI_API_BASE=http://localhost:3100/v1
OPENAI_API_KEY=eliza
```

Или через UI Open Design: Settings → Provider → OpenAI-compatible → ввести baseUrl + apiKey.

### 3. Запустить оба сервиса

```bash
# Terminal 1 — eliza-proxy
cd /path/to/eliza-proxy && npm start

# Terminal 2 — Open Design daemon
cd /path/to/open-design && npm run daemon
# или через CLI: open-design daemon
```

## Критические файлы

- `server.js` — основной прокси, все эндпоинты уже там. Изменений не требуется.
- `lib/eliza-client/routing.js` — роутинг по моделям. Проверить если Open Design отправит нестандартные model id.

## Верификация

1. `curl http://localhost:3100/v1/models | jq .data[].id` — список моделей
2. Open Design UI → выбрать OpenAI-compatible провайдер → указать `http://localhost:3100`
3. Сделать тестовый запрос из Open Design → убедиться что ответ приходит
4. Проверить `usage.jsonl` — запросы должны логироваться

## Если нужно — добавить алиасы моделей

Если Open Design шлёт стандартные id (`gpt-4o`, `claude-3-5-sonnet-20241022`) вместо eliza-style (`claude-sonnet-4-6`) — добавить нормализацию в `lib/eliza-client/routing.js`.

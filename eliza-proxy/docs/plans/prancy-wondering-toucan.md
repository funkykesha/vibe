# Plan: OpenAI-compatible endpoint for Open Design

## Context

[Open Design](https://github.com/nexu-io/open-design) — open-source Claude Design альтернатива. Поддерживает BYOK-прокси: пользователь задаёт `baseUrl + apiKey + model`, выбирает провайдер (OpenAI/Anthropic/etc.), и Open Design шлёт стандартные запросы.

Для режима **OpenAI** Open Design вызывает `POST {baseUrl}/v1/chat/completions` с телом OpenAI-формата и ожидает OpenAI SSE chunks.

Текущий eliza-proxy имеет только `/v1/chat` с кастомным форматом `{"text":"..."}`. Нужно добавить `/v1/chat/completions` с OpenAI-совместимым форматом.

## Что делаем

### 1. Новый endpoint `POST /v1/chat/completions` в `server.js`

Добавить в `createApp()` сразу после существующего `/v1/chat`.

**Вход** (OpenAI формат):
```json
{
  "model": "deepseek-v3-2",
  "messages": [
    {"role": "system", "content": "You are a designer"},
    {"role": "user", "content": "Make a landing page"}
  ],
  "stream": true
}
```

**Трансформация запроса:**
- Извлечь сообщения с `role === "system"` → собрать в `system` строку
- Остальные messages передать в `eliza.chat()` как есть

**Выход** (OpenAI SSE формат):

Каждый chunk текста:
```
data: {"id":"chatcmpl-<uuid>","object":"chat.completion.chunk","created":<unix>,"model":"<model>","choices":[{"index":0,"delta":{"content":"Hello"},"finish_reason":null}]}
```

Финальный chunk:
```
data: {"id":"chatcmpl-<uuid>","object":"chat.completion.chunk","created":<unix>,"model":"<model>","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":<N>,"completion_tokens":<N>,"total_tokens":<N>}}
```

Затем: `data: [DONE]`

**id** генерируется один раз на запрос: `"chatcmpl-" + Math.random().toString(36).slice(2, 10)`

**Авторизация:** Open Design шлёт `Authorization: Bearer <key>`. Игнорируем — Eliza token уже загружен из env/файла.

### 2. Использовать существующую логику без изменений

- `eliza.chat(model, messages, { system })` — без изменений
- `recordUsage()` — без изменений
- Обработка ошибок (429, 501, etc.) — те же проверки, но ошибки в OpenAI формате:
  ```json
  {"error":{"type":"rate_limit_error","message":"Rate limit exceeded"}}
  ```

## Критичные файлы

- `server.js:297` — существующий `/v1/chat`, рядом добавить новый endpoint (~70 строк)
- `lib/eliza-client/index.js` — `eliza.chat()`, без изменений
- Тесты: `lib/eliza-client/test/` — не трогаем

## Конфигурация Open Design

После деплоя в Open Design BYOK:
```
baseUrl:  http://localhost:3100
apiKey:   any-value (ignored)
provider: OpenAI
model:    deepseek-v3-2 (или другая доступная модель)
```

## Верификация

1. `npm start` — запустить proxy
2. Ручная проверка:
```bash
curl -N -X POST http://localhost:3100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test" \
  -d '{"model":"deepseek-v3-2","messages":[{"role":"user","content":"hi"}],"stream":true}'
```
Ожидать: SSE chunks с `choices[0].delta.content`, финальный с `finish_reason:"stop"`, затем `[DONE]`.

3. В Open Design: добавить BYOK с `baseUrl=http://localhost:3100`, проверить что дизайн-запрос проходит.
4. `npm test` — существующие 77 тестов должны пройти без изменений.

# Plan: 429 retry with backoff in `chat()`

## Context

При rate limit Eliza возвращает HTTP 429, иногда с заголовком `Retry-After`.
Сейчас `chat()` бросает `ElizaError(429)` сразу — клиент получает SSE-ошибку без retry.
Цель: автоматически повторить fetch с backoff до 2 раз перед тем как пробросить ошибку.

## Что нашли в доках

- Eliza отвечает 429 при превышении RPM/TPM на уровне OAuth-токена
- `Retry-After` заголовок — иногда есть (значение в секундах), иногда нет
- FAQ: "Quota exceeded" на внутренних моделях → "проверьте URL" (обычно ошибка навигации)
- Внешние модели: "select key: no keys found for vendor" = закончились деньги, retry не поможет

## Реализация

### Файл: `lib/eliza-client/index.js`

**`chat()` (строки 127–169)** — обернуть `fetch()` в retry loop перед `normalizeStream`:

```javascript
async function* chat(model, messages, { system } = {}) {
  const config = elizaConfig(model, baseUrl);
  if (config.supportsStreaming === false) {
    throw new ElizaError(501, `Streaming not supported for model: ${model}`);
  }

  const isReasoning = usesReasoningTokens(model);
  const body = /* ...без изменений... */;

  const backoffMs = [1000, 2000];
  let attempt = 0;
  let res;

  while (true) {
    res = await fetch(config.url, {
      method: 'POST',
      headers: { Authorization: `OAuth ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    if (res.ok) break;

    if (res.status === 429 && attempt < backoffMs.length) {
      const retryAfterSec = res.headers.get('Retry-After');
      const delayMs = retryAfterSec ? parseFloat(retryAfterSec) * 1000 : backoffMs[attempt];
      await _sleep(delayMs);
      attempt += 1;
      continue;
    }

    throw new ElizaError(res.status, await res.text().catch(() => ''));
  }

  for await (const chunk of normalizeStream(res.body, config.format)) {
    if (chunk.usage) {
      console.log(`[eliza-client] usage model=${model} input=${chunk.usage.input} output=${chunk.usage.output}`);
    }
    yield chunk;
  }
}
```

Ключевые моменты:
- `_sleep` уже инжектируется через параметры `createElizaClient` → тесты могут его мокать
- `backoffMs.length = 2` → максимум 2 retry (3 попытки итого)
- `Retry-After` приоритет над hardcoded backoff
- После исчерпания попыток — бросает `ElizaError(429)` как раньше
- `server.js` уже ловит 429 и отправляет `{"error": "Rate limit exceeded"}` — без изменений

### Файлы: без изменений

- `server.js` — уже корректно обрабатывает `ElizaError(429)`
- `probe.js` — уже имеет свою логику для 429 (retryable)

## Тесты

Файл: `lib/eliza-client/test/index.test.js` (или отдельный `chat.test.js` если suite большая)

Новые тест-кейсы:
1. **429 → retry → success**: первые N fetch возвращают 429, последний — 200. Проверить что `_sleep` вызван с правильными задержками.
2. **429 с `Retry-After`**: заголовок `Retry-After: 5` → delay 5000ms.
3. **429 exhausted**: 3 fetch подряд возвращают 429 → `ElizaError(429)` выброшен, не проглочен.
4. **Другой HTTP error не retry**: 500 → сразу throw, `_sleep` не вызван.

## Тестирование curl

```bash
# Проверить что retry происходит — нужен mock или интеграция
# Живой тест (если токен под лимитом):
curl -X POST http://localhost:3100/v1/chat \
  -H 'Content-Type: application/json' \
  -d '{"model":"deepseek-v3-1-terminus","messages":[{"role":"user","content":"hi"}]}' \
  -N  # -N = no-buffer, видеть SSE в реальном времени
```

## Порядок изменений

1. Обновить `chat()` в `lib/eliza-client/index.js`
2. Добавить тесты для retry логики
3. Синхронизировать `../groovy_agent/lib/eliza-client/index.js` (CLAUDE.md: источник истины)

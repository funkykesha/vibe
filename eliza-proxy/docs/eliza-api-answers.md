# Ответы команде genidea: Eliza API через groovy_agent

**Дата:** 2026-04-26  
**От:** groovy_agent team  
**Контекст:** вы строите genidea поверх groovy_agent → Eliza; переходим к прямому доступу через `eliza-proxy`

---

## 1. Usage в SSE — есть ли? groovy_agent стрипает?

**Да, стрипает. Вот факты:**

Eliza возвращает usage в обоих форматах:
- **Anthropic**: `message_delta` событие, поля `usage.input_tokens` / `usage.output_tokens`
- **OpenAI-совместимый**: финальный чанк, поля `usage.prompt_tokens` / `usage.completion_tokens`

`groovy_agent/lib/eliza-client/streaming.js` нормализует usage в:
```js
{ delta: '', done: false, usage: { input: N, output: N } }
```

Но `server.js /api/chat` **игнорирует** эти чанки — пишет только `text` и `[DONE]`.

**Что изменится в `eliza-proxy`:**

Стрим будет включать usage-чанк перед `[DONE]`:
```
data: {"text":"кусок текста"}\n\n
data: {"text":"ещё кусок"}\n\n
data: {"usage":{"input":1240,"output":380,"model":"claude-sonnet-4-6","cost_usd":0.003140}}\n\n
data: [DONE]\n\n
```

`cost_usd` считается из prices модели (см. п. 2).

**Временный workaround если нужно сейчас:**  
Можно обратиться к Eliza напрямую (у вас есть токен) — см. п. 6.

---

## 2. Прайс — есть $/1K tokens?

**Да, есть.** Endpoint `/api/models` (и будущий `/v1/models`) возвращает `prices` для каждой модели.

Пример из текущих данных (Claude Sonnet):
```json
{
  "id": "claude-sonnet-4-6",
  "prices": {
    "input_tokens":              "0.000003",
    "output_tokens":             "0.000015",
    "input_cache_read_tokens":   "0.0000003",
    "input_cache_write_1h_tokens":"0.0000038",
    "input_cache_write_5m_tokens":"0.00000375"
  }
}
```

**Единицы:** доллары за **один** токен (т.е. умножайте на 1000 для $/1K или на 1_000_000 для $/M).

Формула cost estimation:
```js
const cost = (usage.input * prices.input_tokens) + (usage.output * prices.output_tokens);
```

`eliza-proxy` будет возвращать `cost_usd` прямо в usage-чанке стрима.

---

## 3. `/api/models` — полный список? TTL кеша?

**Список**: да, полный (после фильтрации). Eliza отдаёт ~100+ моделей, `parseModels()` фильтрует:
- Тестовые namespace (`eliza_test`, `alice`, `gena_offline_batch_inference`)
- Не-чат модели (TTS, Whisper, DALL-E, embedding, image-gen)
- Дата-версионированные ID (устаревшие)
- Дубли (один canonical per family)

Итог: ~22 рабочих модели (Claude Haiku/Sonnet/Opus, GPT-4.1/4o, Gemini 2.5 Flash/Pro, DeepSeek V3/R1, Qwen3, Grok 3/4, Kimi, GLM, Alice и др.)

**TTL кеша:**
| Уровень | Сейчас | В eliza-proxy |
|---------|--------|----------------|
| Список моделей (fetch) | In-memory до рестарта | 1h TTL + принудительный refresh |
| Probe (валидация доступа) | Один раз при старте, cooldown 30s | Каждые 6h или по запросу |
| `validated: true` | После probe | После probe |

Пока `validated: false` — список raw (не проверен на доступность). `validated: true` — каждая модель в списке реально отвечала.

---

## 4. Rate limits — есть? 429 + Retry-After?

**groovy_agent: нет обработки.** Если Eliza вернёт 429, groovy_agent пробросит ошибку в SSE:
```
data: {"error":"Eliza error 429: Too Many Requests"}\n\n
```

**Eliza API**: лимиты есть (Yandex внутренняя инфраструктура), точные значения не задокументированы публично. По практике:
- Ограничения по RPM/TPM на уровне OAuth-токена
- При превышении: HTTP 429, иногда с `Retry-After` заголовком, иногда без

**В `eliza-proxy` будет:**
- Перехват 429 от Eliza
- Forward `Retry-After` в ответ клиенту
- Exponential backoff retry для probe-запросов (не для чата — клиент решает сам)
- `/v1/health` показывает текущий статус rate limiting

---

## 5. Мониторинг — дашборд/endpoint по usage команды?

**Сейчас: нет.** В `lib/eliza-client` (Task 7) добавлено логирование:
```
[eliza-client] usage model=claude-sonnet-4-6 input=1240 output=380
```
Только в stdout, нет агрегации.

**В `eliza-proxy` будет:**
- `GET /v1/usage` — агрегированная статистика (in-memory, сбрасывается при рестарте)
  ```json
  {
    "total_requests": 142,
    "total_input_tokens": 840200,
    "total_output_tokens": 124300,
    "total_cost_usd": 3.47,
    "by_model": { "claude-sonnet-4-6": { ... }, ... },
    "last_reset": "2026-04-26T00:00:00Z"
  }
  ```
- Persistent storage (append to JSONL файл) — для анализа между рестартами
- Дашборд не планируется в v1 — интегрируйте Grafana/ClickHouse сами через JSONL лог

---

## 6. Можно ли обращаться к Eliza напрямую, если groovy_agent не даёт usage?

**Технически да**, но это временный путь. Вот что нужно знать:

**Auth:**
```
Authorization: OAuth <ELIZA_TOKEN>
```
(не Bearer — именно OAuth)

**Роутинг — зависит от модели:**

| Модель | Endpoint | Формат |
|--------|----------|--------|
| Claude | `https://api.eliza.yandex.net/raw/anthropic/v1/messages` | Anthropic |
| GPT-4o, Gemini, DeepSeek, Grok | `https://api.eliza.yandex.net/raw/openrouter/v1/chat/completions` | OpenAI |
| GPT-4.1, o1/o3/o4 | `https://api.eliza.yandex.net/raw/openai/v1/chat/completions` | OpenAI |
| Internal (GLM, GPT-OSS, Alice, Qwen3-coder) | `https://api.eliza.yandex.net/raw/internal/<model>/...` | OpenAI |

Полная таблица роутинга в `lib/eliza-client/routing.js` функция `elizaConfig()`.

**Особенности:**
- Reasoning модели (o1/o3/o4/grok): системное сообщение должно быть `role: 'developer'`, не `'system'`
- Reasoning модели: НЕ передавать `temperature`
- GPT-5 (gpt-5, gpt5, gpt-5.1): SSE **не поддерживается** — нужен `/v1/responses` endpoint
- Claude: `max_tokens` обязателен

**Рекомендация:** дождитесь `eliza-proxy` (срок ~1-2 дня) — он берёт всё это на себя. Прямые вызовы придётся поддерживать и обновлять вручную при изменении роутинга.

---

## Резюме: что получите с eliza-proxy

| Что | Сейчас (groovy_agent) | После (eliza-proxy) |
|-----|----------------------|---------------------|
| Usage в стриме | ❌ стрипается | ✅ `data: {"usage":{...}}` |
| cost_usd в стриме | ❌ | ✅ |
| Prices в /models | ✅ есть | ✅ есть |
| Rate limit handling | ❌ пробрасывает ошибку | ✅ 429 + Retry-After |
| Monitoring endpoint | ❌ | ✅ /v1/usage |
| TTL на список моделей | ❌ до рестарта | ✅ 1h |
| Прямой доступ из браузера | ✅ через groovy_agent | ✅ напрямую к eliza-proxy |
| Документированный API | частично | ✅ полностью |

---

## Ближайшие шаги для genidea

После деплоя eliza-proxy:

1. Изменить `AGENT_BASE_URL` с `localhost:3000` на `localhost:PORT_ELIZA_PROXY`
2. Изменить путь с `/api/chat` на `/v1/chat`
3. Добавить обработку `data: {"usage":{...}}` в SSE-ридере:
   ```js
   if (msg.usage) {
     console.log(`Cost: $${msg.usage.cost_usd.toFixed(4)}`);
     // или показать в UI
   }
   ```
4. Убрать `currentCode: ''` и `inputData: '{}'` из запроса — они не нужны eliza-proxy

Вопросы → @groovy_agent team.

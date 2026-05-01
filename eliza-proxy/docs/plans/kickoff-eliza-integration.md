# Kickoff: Интеграция genidea ↔ groovy_agent (Eliza API)

**Дата:** 2026-04-25  
**Цель:** Подключить реальный LLM к genidea вместо mock.  
**Срок:** ~1 рабочий день (все задачи XS–S).

---

## Контекст

**genidea** — одностраничный HTML-инструмент для генерации AI-промптов.  
`/Users/agaibadulin/Desktop/projects/vibe/genidea/index.html`  
Стек: React 18 CDN + Babel, без сборки, открывается файлом в браузере.

**groovy_agent** — Express-прокси к Eliza API (Yandex).  
`/Users/agaibadulin/Desktop/projects/vibe/groovy_agent`  
Стек: Node.js 18+, Express, порт 3000.  
Auth: `ELIZA_TOKEN` в `.env` — сервер ставит заголовок сам.

Браузер → `http://localhost:3000/api/chat` → groovy_agent → Eliza → модель.

---

## Что сейчас работает

### groovy_agent

| Эндпоинт | Статус | Нужен genidea |
|----------|--------|---------------|
| `GET /api/models` | ✅ работает | ✅ да |
| `POST /api/chat` | ✅ работает (SSE) | ✅ да |
| CORS | ❌ нет | ❌ блокирует браузер |

**SSE-формат `/api/chat`:**
```
← data: {"text":"кусок текста"}\n\n
← data: {"text":"ещё кусок"}\n\n
← data: [DONE]\n\n
← data: {"error":"описание"}\n\n  ← при ошибке
```

**Запрос:**
```json
POST /api/chat
{
  "model": "claude-sonnet-4-6",
  "messages": [
    { "role": "system", "content": "Ты элитный prompt engineer..." },
    { "role": "user",   "content": "Тип задачи: code\nЗадача: ..." }
  ],
  "currentCode": "",
  "inputData": "{}"
}
```

**Модели (22 шт.):** Claude Haiku/Sonnet/Opus, GPT-4.1/4o, Gemini 2.5 Flash/Pro, DeepSeek V3, Qwen, Grok, Kimi, GLM.

### genidea

| Что | Статус |
|-----|--------|
| `callModel(system, user, model)` | ✅ сигнатура верная, тело — mock |
| Все prompt builders | ✅ готовы |
| Error handling + retry UI | ✅ есть |
| Loading states | ✅ есть |
| MODEL_LIST | ⚠️ захардкожено (3 модели, старые id) |
| `system` в вызовах | ⚠️ тип ('content'), не промпт |
| Ввод URL сервера | ❌ нет |

---

## Задачи

### groovy_agent (1 задача)

**T1 — Добавить CORS** `[XS, ~5 мин]`

```bash
cd groovy_agent && npm install cors
```

В `server.js` после `const app = express();`:
```js
const cors = require('cors');
app.use(cors({ origin: '*' }));   // dev-режим, для прода сузить
```

---

### genidea (5 задач)

**T2 — Константы подключения** `[XS]`

Добавить в начало скрипта:
```js
const AGENT_BASE_URL = 'http://localhost:3000';
```

**T3 — Обновить MODEL_LIST** `[XS]`

Заменить захардкоженные 3 модели на актуальные (взять из `GET /api/models`). Минимальный сет:
```js
const MODEL_LIST = [
  { id: 'claude-sonnet-4-6',  label: 'Claude Sonnet 4.6',  provider: 'anthropic' },
  { id: 'claude-haiku-4-5',   label: 'Claude Haiku 4.5',   provider: 'anthropic' },
  { id: 'gpt-4o',             label: 'GPT-4o',              provider: 'openai'    },
  { id: 'gemini-2.5-flash',   label: 'Gemini 2.5 Flash',    provider: 'google'    },
  { id: 'deepseek-v3-2',      label: 'DeepSeek V3',         provider: 'deepseek'  },
];
```

**T4 — Определить system-промпты** `[S]`

Сейчас `callModel('content', ...)` — `'content'` это ключ мока.  
Для реального API нужны строки. Добавить константы:

```js
const SYSTEM_PROMPTS = {
  generate:
    `Ты элитный prompt engineer. Создай детальный структурированный промпт для мощной AI-модели на основе данных пользователя. Структура: Роль → Контекст → Задача → Формат → Ограничения. Верни ТОЛЬКО текст промпта, без преамбулы и объяснений.`,

  parse_xml:
    `Разбери промпт на смысловые блоки. Используй теги из набора: role, context, task, format, constraints, examples. Верни ТОЛЬКО JSON-массив: [{"tag":"role","content":"..."}]. Без markdown, без преамбулы.`,

  transform:
    `Ты prompt engineer. Преобразуй промпт согласно инструкции пользователя. Верни ТОЛЬКО изменённый промпт, без объяснений и преамбулы.`,

  refine:
    `Ты prompt engineer. Улучши промпт согласно пожеланию пользователя. Верни ТОЛЬКО улучшённый промпт, без объяснений и преамбулы.`,
};
```

Обновить вызовы — заменить тип на промпт:
```js
// было
callModel(state.a.type || 'content', buildPromptA(state.a), state.selectedModel)
// стало
callModel(SYSTEM_PROMPTS.generate, buildPromptA(state.a), state.selectedModel)
```

| Место вызова | Было | Стало |
|---|---|---|
| `handleGenerate` | `state.a.type \|\| 'content'` | `SYSTEM_PROMPTS.generate` |
| `handleParseXML` | `'content'` | `SYSTEM_PROMPTS.parse_xml` |
| `handleTransformB2b` | `'content'` | `SYSTEM_PROMPTS.transform` |
| `handleRefine` | `'content'` | `SYSTEM_PROMPTS.refine` |
| `translateEN` | `'content'` | `SYSTEM_PROMPTS.refine` |

**T5 — Реализовать `callModel` с SSE** `[S]`

Заменить mock-тело на реальный fetch + SSE-ридер:

```js
const callModel = async (systemPrompt, userMessage, model) => {
  const response = await fetch(`${AGENT_BASE_URL}/api/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model,
      messages: [
        { role: 'system',  content: systemPrompt },
        { role: 'user',    content: userMessage  },
      ],
      currentCode: '',
      inputData:   '{}',
    }),
  });

  if (!response.ok) throw new Error(`HTTP ${response.status}`);

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let result = '';
  let buffer = '';

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split('\n');
    buffer = lines.pop();                         // незавершённая строка обратно
    for (const line of lines) {
      if (!line.startsWith('data: ')) continue;
      const payload = line.slice(6).trim();
      if (payload === '[DONE]') return result;
      const msg = JSON.parse(payload);
      if (msg.error) throw new Error(msg.error);
      if (msg.text)  result += msg.text;
    }
  }
  return result;
};
```

**T6 — Fallback: mock-режим если сервер недоступен** `[XS, опционально]`

В начале `callModel` обернуть в try, при `fetch` ошибке (`Failed to fetch`) бросить понятное сообщение:
```js
// Уже покрыто showError() в App — отдельной задачи нет
```

---

## Порядок выполнения

```
T1 (groovy_agent: CORS) → T2 → T3 → T4 → T5 → проверка
```

T4 и T5 независимы, можно параллельно.

---

## Верификация

1. `cd groovy_agent && npm run dev` — сервер поднят, токен в `.env`
2. Открыть `genidea/index.html` в браузере
3. Flow A: Mode → A1 → A2 → A4 (задача) → A5 → Сгенерировать → реальный промпт за ~2–5 сек
4. Flow B2b: вставить промпт → Преобразовать → выбрать карточку → результат
5. Flow B2a: вставить промпт → Разобрать → XML-блоки из реального JSON
6. ResultScreen: `↺ Уточнить` → «сделай короче» → обновлённый промпт
7. `🌍 → EN` → текст переведён
8. Сменить модель на `gemini-2.5-flash` → генерация работает

---

## Риски

| Риск | Вероятность | Митигация |
|------|-------------|-----------|
| `ELIZA_TOKEN` истёк | Средняя | `GET /api/models` вернёт 500 — сразу видно |
| Модель недоступна | Низкая | groovy_agent пробирует модели при старте |
| Длинный промпт → таймаут | Низкая | В genidea нет chat-таймаута, у Eliza есть лимиты токенов |
| Ответ не-JSON в B2a (parse_xml) | Средняя | `parseXMLBlocks()` уже defensive — обработано |

---

## Open questions

- [ ] Нужен ли стриминг в UI (typewriter-эффект)? Сейчас `callModel` накапливает весь текст.
- [ ] Какую модель ставить по умолчанию? (предлагаю `claude-sonnet-4-6`)
- [ ] URL сервера hardcode `localhost:3000` или поле ввода в Header?

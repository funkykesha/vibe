# Active Context

## Current Session

**Task:** Завершение спринтов 3–5 + интеграция реального API через groovy_agent

**Status:** Все спринты завершены. Реальный API подключён через groovy_agent (Eliza). Проект готов к использованию.

### Что сделано в этой сессии

#### Sprint 3–5 доработки (по plan-v2.md)
- ✅ Баг translateEN — теперь обновляет `state.result.text`
- ✅ Tag rename в B2a — кнопка [✏️] + inline input
- ✅ ErrorScreen + `showError()` + retry во всех handlers
- ✅ Hotkeys: Cmd+Enter (Далее/Генерировать по шагу), Esc (назад)
- ✅ Stagger delay 0.04s → 0.05s
- ✅ Mobile: `data-drag-handle` + `@media (max-width:600px)` скрывает ↕
- ✅ Кнопка «✏️ Преобразовать» в B2a → переход на B2b

#### Интеграция groovy_agent (Eliza API)
- ✅ T1: CORS добавлен в groovy_agent (`cors` пакет, `app.use(cors({origin:'*'}))`)
- ✅ T2: `AGENT_BASE_URL = 'http://localhost:3000'`
- ✅ T3: MODEL_LIST обновлён — 5 реальных моделей (claude-sonnet-4-6, haiku, gpt-4o, gemini-2.5-flash, deepseek-v3-2)
- ✅ T4: `SYSTEM_PROMPTS` объект (generate, parse_xml, transform, refine) + 5 call sites обновлены
- ✅ T5: `callModel()` — реальный SSE fetch через `response.body.getReader()`
- ✅ T6: Error fallback при недоступном сервере

### Текущее состояние

- Оба флоу (A и B) работают с реальным API
- groovy_agent проксирует к Yandex Eliza (22 модели: Claude, GPT, Gemini, DeepSeek, Grok...)
- Auth: `ELIZA_TOKEN` в `.env` groovy_agent — genidea не требует ключей
- Streaming: SSE накапливается целиком, отображается после `[DONE]`
- ErrorScreen с retry при любых сбоях API

### Что сделано (Sprint 6)

- ✅ System prompts → английский + "respond in user's language"
- ✅ Дефолт → claude-haiku-4-5 (быстрее)
- ✅ Динамический список моделей из `/api/models` (все доступные, не 5 хардкодных)
- ✅ A2b экран — выбор инструмента для code-флоу (Chat / Claude Code / Codex / YCA)
- ✅ Log server: `genidea/log-server.js`, порт 3001, `logs/requests.jsonl`
- ✅ fire-and-forget логирование после каждой генерации

### Архитектурное уточнение

genidea → groovy_agent (чужая команда, port 3000) → Eliza (Yandex gateway) → LLM

### Следующие шаги

- **P1:** Typewriter-эффект (streaming display по мере SSE)
- **P1:** `/stats` в log-server (аггрегаты)
- **P2:** Мобильная адаптация B2a (↑↓ вместо DnD)
- **P0-blocked:** Токены в логах — ждём ответ команды Eliza (usage в SSE? прямой вызов?)

### Запрос к Eliza team (pending)

Ключевой вопрос: передают ли usage (input/output tokens) в SSE stream? groovy_agent сейчас стрипает. Нужно для токен-аналитики.

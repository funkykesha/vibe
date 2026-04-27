# Progress

## Completed

### Sprint 1 — Skeleton + Design System
- [x] Create `index.html` with React 18 CDN + Babel
- [x] CSS token variables (dark/light theme)
- [x] Header: logo, model selector, reset, theme toggle
- [x] ModeScreen: two choice cards
- [x] Navigation state machine: all screens connected
- [x] Component structure ready for logic

### Sprint 2 — Flow A Implementation
- [x] A1: mode selection (new/continue)
- [x] A2: result type (content/code/report)
- [x] A3: notes textarea, skip if mode===new
- [x] A4: task textarea, char counter, validation (≥20 chars)
- [x] A5: progress bar (5 dots), question carousel, preview next, 3 buttons
- [x] A5: «⚡ Генерировать сейчас» (skip remaining questions)
- [x] A5: Last question → «Сгенерировать →»
- [x] ResultScreen: copy (✓ 2s), refine field (API call), reset

### Sprint 3 — Flow B + API mock
- [x] B1: textarea + 2 buttons (active if non-empty)
- [x] B2b: 4 transform cards (multi-select) + custom field
- [x] LoadingScreen: spinner + message
- [x] ResultScreen: copy, 🌍→EN (updates text ✅ fixed), ↺ Уточнить, reset

### Sprint 4 — B2a XML Editor
- [x] Mock parse: prompt → callModel → defensive JSON extract
- [x] Render blocks: tag, textarea, buttons [↕][✏️][🗑][📋]
- [x] Edit content in block textarea
- [x] Tag rename: inline input on [✏️] click ✅ added
- [x] Delete block
- [x] Missing tags indicator (6 standard tags)
- [x] Copy single tag + copy all XML
- [x] HTML5 DnD: draggable, dragStart/dragOver/drop
- [x] «✏️ Преобразовать» button → navigate to B2b ✅ added

### Sprint 5 — Polish
- [x] fadeUp animations + stagger 0.05s per child ✅ fixed
- [x] Dark/Light theme toggle ☀️/🌙
- [x] Chips for «Тон и стиль» (6) and «Формат вывода» (6)
- [x] GhostBtn: text var(--text), border var(--muted), hover bg surface-2
- [x] ErrorScreen + showError() + retry in all handlers ✅ added
- [x] Hotkeys: Cmd+Enter (next step), Esc (back) ✅ added
- [x] Mobile: data-drag-handle + @media 600px hides ↕ ✅ added

### Real API Integration (groovy_agent / Eliza)
- [x] CORS в groovy_agent (cors package, origin:*)
- [x] AGENT_BASE_URL = 'http://localhost:3000'
- [x] MODEL_LIST: 5 реальных моделей (claude-sonnet-4-6, haiku, gpt-4o, gemini-2.5-flash, deepseek-v3-2)
- [x] SYSTEM_PROMPTS: generate, parse_xml, transform, refine
- [x] callModel(): реальный SSE fetch (response.body.getReader)
- [x] Error fallback при недоступном сервере

### Sprint 6 — Improvements
- [x] System prompts → английский (token economy, ответ на языке пользователя)
- [x] Дефолтная модель → claude-haiku-4-5 (быстрее)
- [x] Динамический MODEL_LIST из GET /api/models (все модели Eliza, не 5)
- [x] A2b шаг — выбор инструмента для code-флоу (Chat / Claude Code / Codex / YCA)
- [x] `tool` поле в state.a + buildPromptA включает Target tool
- [x] goBack map обновлён (A2b → A2, A4/A3 учитывают type===code)
- [x] Log server: `genidea/log-server.js` (Express port 3001, JSONL)
- [x] `package.json` для genidea (express + cors)
- [x] fire-and-forget логирование в handleGenerate/Transform/Refine

---

## Next

- [ ] Typewriter-эффект (стриминг по мере получения чанков)
- [ ] `/stats` в log-server (аггрегаты по модели/типу/длительности)
- [ ] История промптов (последние N в log-server)
- [ ] Мобильная адаптация B2a: кнопки ↑↓ вместо DnD
- [ ] Токены в логах (ждём ответ от Eliza team)
- [ ] Cost estimate per request

---

## Blockers

- Реальные токены в логах — ждём ответ от команды Eliza: передают ли usage в SSE?
- groovy_agent стрипает usage из stream (видели в server.js)
- Eliza token есть, прямой вызов в обход groovy_agent — нужно согласовать

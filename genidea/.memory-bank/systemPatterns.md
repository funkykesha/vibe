# System Patterns

## React State Architecture

**Single state object** with branches:
```js
{
  branch: 'A'|'B'|null,
  step: 'mode'|'A1'|'A2'|'A2b'|'A3'|'A4'|'A5'|'B1'|'B2a'|'B2b'|'result',
  a: { mode, type, tool, notes, task, questionIndex, answers[5] },
  b: { inputPrompt, xmlBlocks[], transformCards[], transformCustom },
  result: { text, isEditing },
  selectedModel: string,  // default: claude-haiku-4-5
  loading: boolean,
  loadingMsg: string,
  error: { message, retry }|null,
}
```

**State updaters:**
- `setStep(step)` — navigation
- `setState(updater)` — full state mutation

---

## Component Tree

```
<App>
  <Header />
  <ModeScreen /> | <A1_Screen /> | ... | <ResultScreen />
</App>
```

Each screen is conditional render based on `state.branch && state.step`

---

## API Pattern

```
genidea → groovy_agent (port 3000) → api.eliza.yandex.net → Anthropic/OpenAI/...
```

- **groovy_agent**: другая команда, нормализует SSE, кеширует модели
- **Eliza**: Yandex internal AI gateway (OAuth token)
- **callModel()**: SSE fetch → `response.body.getReader()` → аккумулирует chunks → return при `[DONE]`
- **AGENT_BASE_URL**: `http://localhost:3000`
- **LOG_BASE_URL**: `http://localhost:3001` (наш log-server, опциональный)

```js
const callModel = async (systemPrompt, userMessage, model) => {
  const response = await fetch(`${AGENT_BASE_URL}/api/chat`, { method:'POST', ... });
  // SSE stream reading loop → return accumulated result on [DONE]
};
```

**Логирование**: fire-and-forget POST на `localhost:3001/log` после каждой генерации.

---

## Questions System

**Common questions (1–4):**
```js
const QUESTIONS_COMMON = [
  'Для кого этот результат?',
  'Какой тон и стиль?',
  'Какой формат вывода?',
  'Что точно НЕ нужно?',
];
```

**Type-specific question 5:**
```js
const QUESTIONS_5 = {
  content: 'Есть ли примеры или референсы...',
  code: 'На каком языке/стеке...',
  report: 'Есть ли шаблон или стандарт...',
};
```

---

## Navigation Logic

**Flow A:** mode → type → **[A2b если type===code]** → (notes if continue) → task → questions → result

**Flow B:** paste → parse XML OR transform → result

**Skip logic:** A3 skipped if `a.mode === 'new'`; A2b вставляется только для `type === 'code'`

**A2b — инструменты:** Chat / Claude Code / Codex / Yandex Code Assistant → `state.a.tool`

---

## XML Tags (B2a)

Fixed 6-tag set:
- `role`, `context`, `task`, `format`, `constraints`, `examples`

Missing tags shown as warning chips below editor.

---

## Design System

**Tokens (CSS variables):**
- Accent: `#f59e0b` (dark) / `#d97706` (light)
- Text: `var(--text)` — всегда контрастный цвет
- Muted: `var(--muted)` — для обводок кнопок
- Surface-2: `var(--surface-2)` — hover-фон

**Themes:**
- Dark: `:root` — фон `#161311`
- Light: `:root[data-theme="light"]` — фон `#faf8f5`
- Переключатель в Header через `data-theme` атрибут на `<html>`

**GhostBtn pattern:**
```js
color: 'var(--text)',       // всегда читаем
border: '1px solid var(--muted)',  // видима без наведения
// hover: background var(--surface-2), border var(--text)
```

**Fonts:**
- UI: Inter
- Display: Instrument Serif italic
- Code: Courier New monospace

**Animations:**
- fadeUp: 0.4s, stagger +0.04s per child
- spin: loading indicator

---

## Browser Features Used

- React 18 hooks (CDN)
- HTML5 Drag-and-Drop API (B2a)
- localStorage (future)
- fetch API (for real API later)

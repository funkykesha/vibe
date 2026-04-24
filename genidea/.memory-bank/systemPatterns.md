# System Patterns

## React State Architecture

**Single state object** with branches:
```js
{
  branch: 'A'|'B'|null,
  step: 'mode'|'A1'|'A2'|...|'result',
  a: { mode, type, notes, task, questionIndex, answers[5] },
  b: { inputPrompt, xmlBlocks[], transformCards[], transformCustom },
  result: { text, isEditing },
  selectedModel: string,
  loading: boolean,
  loadingMsg: string,
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

## API Mock Pattern

```js
const callModel = async (system, user, model) => {
  await new Promise(r => setTimeout(r, 1500 + Math.random() * 500));
  return '// faux result...';
};
```

- Delays 1.5–2s to simulate API latency
- Returns plausible dummy text
- Interface identical to real fetch — easy swap for `/groovy_agent`

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

**Flow A:** mode → type → (notes if continue) → task → questions → result

**Flow B:** paste → parse XML OR transform → result

**Skip logic:** A3 skipped automatically if `a.mode === 'new'`

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

# Progress

## Completed

### Sprint 1 — Skeleton + Design System
- [x] Create `index.html` with React 18 CDN + Babel
- [x] CSS token variables (dark theme)
- [x] Header component: logo, model selector, reset button
- [x] ModeScreen: two choice cards
- [x] Navigation state machine: all screens connected
- [x] Mock `callModel()` function
- [x] Component structure ready for logic

### Sprint 2 — Flow A Implementation
- [x] A1: mode selection (new/continue)
- [x] A2: result type (content/code/report)
- [x] A3: notes textarea, skip if mode===new
- [x] A4: task textarea, char counter, validation (≥20 chars)
- [x] A5: progress bar (5 dots), question carousel, preview next, 3 buttons
- [x] A5: «⚡ Генерировать сейчас» button (skip remaining questions)
- [x] A5: Last question → «Сгенерировать →» button
- [x] Mock API: generation prompt (1.5s delay)
- [x] ResultScreen: copy button (✓ Copied for 2s), refine field (API call)
- [x] Refine loop: iterative API calls

---

### Sprint 3 — Flow B Implementation ✅
- [x] B1: textarea + 2 buttons (active if non-empty)
- [x] B2b: 4 transform cards (multi-select) + custom field
- [x] API: generation prompt (flow A)
- [x] API: transform prompt (flow B2b)
- [x] LoadingScreen: spinner + message
- [x] ResultScreen: copy, refine (API call), reset

### Sprint 4 — B2a XML Editor ✅
- [x] Mock parse: defensive JSON extract
- [x] Render blocks: tag, textarea, buttons [↕][🗑][📋]
- [x] Delete block
- [x] Missing tags indicator
- [x] Copy single tag + copy all XML
- [x] HTML5 DnD: draggable, dragStart/dragOver/drop

### Sprint 3.5 + UI polish ✅
- [x] Dark/Light theme: CSS vars + ☀️/🌙 toggle in header
- [x] 🌍 → EN button in ResultScreen
- [x] Chips for "Тон и стиль" (6 options), "Формат вывода" (6 options)
- [x] GhostBtn: text var(--text), border var(--muted), hover bg surface-2

---

## In Progress / Next

### Real API Integration
- [ ] Add API key input (or env var approach)
- [ ] Replace callModel() mock with real fetch (Groq / Anthropic)
- [ ] Error handling for API failures

### Sprint 5 — Polish
- [ ] Mobile adaptation (layout only, no DnD)
- [ ] Keyboard shortcuts: Cmd+Enter, Esc

---

## Blockers

None

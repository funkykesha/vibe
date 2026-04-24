# Project Brief

## Genidea — Prompt Engineer

**Purpose:** Build a web tool for creating and refining AI prompts across different models (Claude, GPT, Gemini)

**Scope:** MVP prototype — two workflows (create/improve), mocked API, desktop DnD support

**Deliverable:** Single `index.html` file (React 18 + Babel CDN, no build system)

---

## Two User Flows

### Flow A — Create Prompt
1. Mode selection → A1 (new/continue) → A2 (type) → A3 (notes, skip if new) → A4 (task) → A5 (5 questions) → Result
2. Optional: refine via "Уточнить" (API call)

### Flow B — Improve Prompt
1. Mode selection → B1 (paste) → B2a (parse XML) or B2b (transform) → Result
2. B2a: edit tags, drag-drop reorder, copy XML
3. B2b: choose cards or custom text → transform

---

## Architecture

**State:** Single React state object tracking:
- `branch` (A/B), `step` (navigation)
- Ветка A: mode, type, notes, task, answers[5]
- Ветка B: inputPrompt, xmlBlocks, transformCards

**API:** Mocked `callModel(system, user, model)` — returns faux prompt text
- Real integration from `/projects/vibe/groovy_agent` later

**Design:** Dark theme (amber accent #f59e0b), Inter UI font, no grid/glow background

---

## MVP Criteria

✅ Flow A: mode → type → task → questions → result  
✅ Flow B: paste → parse XML OR transform → result  
✅ B2a: drag-drop reorder, tag edit, copy  
✅ Result: copy button, refine button (API), reset  
⬜ Mobile: layout works (no DnD on B2a)  
⬜ Error handling: try/catch, inline messages  

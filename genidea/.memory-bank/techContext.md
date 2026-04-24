# Tech Context

## Stack

- **Runtime:** React 18 (CDN + Babel standalone)
- **No build system** — single `index.html` file
- **Browser APIs:** HTML5 DnD, fetch, localStorage
- **Styling:** CSS variables + inline styles (Tailwind-free)
- **Fonts:** Google Fonts (Inter, Instrument Serif)

## Development

**File:** `/Users/agaibadulin/Desktop/projects/vibe/genidea/index.html`

**Open:** Double-click in Finder or `open index.html` in browser (no server needed)

**Live reload:** Edit file → refresh browser

## Model Selector

`MODEL_LIST` in JS:
```js
const MODEL_LIST = [
  { id: 'claude-sonnet', label: 'Claude Sonnet', provider: 'anthropic' },
  { id: 'gpt-4o', label: 'GPT-4o', provider: 'openai' },
  { id: 'gemini-1.5-pro', label: 'Gemini 1.5 Pro', provider: 'google' },
];
```

Add/remove models here. Currently used in UI only (state.selectedModel), real API integration later.

## Mock API

```js
const callModel = async (system, user, model) => {
  await new Promise(r => setTimeout(r, 1500 + Math.random() * 500));
  return `// Вот ваш промпт для ${model}...`;
};
```

Replace this function with real fetch to `/groovy_agent` API.

## Browser Compat

- Modern browsers (Chrome, Safari, Firefox)
- DnD: desktop only
- Mobile: works except DnD in B2a

## Resources

- Plan: `/Users/agaibadulin/.claude/plans/mutable-wandering-peach.md`
- Old code (reference): `prompt-engineer.jsx`
- Design System: `Design System.html`
- Flow docs: `prompt-engineer-flow-v3.md`

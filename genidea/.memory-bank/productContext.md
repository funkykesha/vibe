# Product Context

## Value Proposition

Help users (developers, prompt engineers) craft better AI prompts by:
1. **Creating** — structured wizard (5 questions → prompt)
2. **Improving** — parse existing prompt → edit blocks → refine

## User Flows

### Flow A: Create
- User answers 5 contextual questions
- AI synthesizes structured prompt
- Can refine iteratively ("Что изменить?")
- Copy & use

### Flow B: Improve
- Paste existing prompt
- Parse into semantic blocks (role, context, task, format, constraints, examples)
- Edit tags, reorder, copy
- OR: choose transformation (compress, change tone, translate, etc.)

## Quality Goals

- **Accessibility:** no auth, no accounts (v1)
- **Speed:** each screen <500ms, API latency visible (spinner)
- **Clarity:** minimal UI, clear labeling in Russian
- **Flexibility:** supports multiple AI models in selector

## Scope (MVP)

✅ Two flows, mocked API  
✅ Desktop DnD in B2a  
⬜ Mobile (layout ok, no DnD)  
⬜ Sharing, history, auth  
⬜ Real API integration (v2, from groovy_agent)  

## Success Metrics

- All screens reachable and functional
- Copy button works
- Mock API shows loading state
- B2a DnD allows reordering
- No crashes on edge cases


# AGENTS.md

## Purpose
- This repo is a local AI workbench for generating and executing Groovy scripts that transform JSON.
- Runtime shape is fixed: `server.js` serves the API and static files, `public/index.html` contains the whole frontend, `lib/eliza-client/` contains the Eliza integration.
- Prefer small, surgical edits. Preserve current UX and API behavior unless the user explicitly asks to change it.

## Context Discipline
- Read `ARCHITECTURE.md` before making changes.
- Do not read large files blindly. Search first with `rg`, then open only the relevant range.
- Do not read `models.json` fully; inspect only the header or targeted fragments.
- Keep responses short: state intent, make the change, report the result.

## Key Project Areas
- `server.js`: Express app, SSE chat proxy, Groovy execution, knowledge/rules CRUD.
- `public/index.html`: single-file frontend with chat, editors, diff highlighting, modals.
- `lib/eliza-client/`: model parsing, routing, probing, stream normalization.
- `knowledge/*.md`: injected into the system prompt as domain knowledge.
- `rules.json`: user-defined prompt rules, must remain valid JSON.

## Change Workflow
- Before editing, list the files you will modify.
- State briefly how the change fits the existing architecture without breaking it.
- Modify only files directly related to the request.
- If another file seems necessary but the user did not ask for it, stop and ask first.

## Invariants
- Keep these HTTP endpoints stable unless the user explicitly requests an API change:
  - `GET /api/models`
  - `POST /api/models/test`
  - `POST /api/chat`
  - `POST /api/execute`
  - `GET/POST/DELETE /api/knowledge`
  - `GET/POST /api/rules`
- Do not break the SSE response format used by `/api/chat`.
- Do not change function signatures without updating every caller.
- Do not refactor outside the task scope.
- Do not expose `ELIZA_TOKEN` to the client.

## Implementation Rules
- Preserve the current split between backend prompt-building logic and frontend editor/chat logic.
- Keep Groovy execution behavior compatible with stdin JSON input and stdout JSON output.
- Treat `lib/eliza-client/` as a reusable library: prefer targeted fixes with tests over ad hoc changes in `server.js`.
- When changing model routing or stream normalization, update or add tests in `lib/eliza-client/test/`.

## Verification
- After every change, run `npm test`.
- If tests fail because of your change, revert the change and explain the failure instead of patching blindly.
- If you change behavior outside `lib/eliza-client/`, still run `npm test` and call out any gaps in coverage.


# Agent Rules

## 1. Context & Tool Discipline (CRITICAL)
- **Do not read entire files blindly.** Use `Grep` to find specific keywords/functions first, then use `Read` with `offset` and `limit` to examine only the relevant blocks.
- **Never read large JSON/data files entirely.** If you need to understand data structure (e.g., `models.json`), read only the first 30-50 lines.
- **Avoid "Explore" agents for small/known codebases.** Use direct, surgical tool calls instead.
- **Keep responses concise.** Do not generate exhaustive explanations of code structures unless explicitly asked. Say what you will do, do it, and report the result.

## 2. Before any change
- Read `ARCHITECTURE.md` silently to understand project layout and conventions.
- List files to be modified.
- State briefly how the change fits existing logic without breaking it.

## 3. Invariants (never break)
- API contracts in `/api/routes` must stay stable.
- Do not change function signatures without updating ALL callers.
- Do not refactor outside the specific task scope. Note potential improvements in comments only.

## 4. Scope discipline
- Modify ONLY files directly related to the user's task.
- If touching a file seems necessary but wasn't mentioned — stop and ask the user first.

## 5. After every change
- Run: `npm test`
- If tests fail — revert the change immediately and explain why. Do not try to blindly patch tests to fit broken code.

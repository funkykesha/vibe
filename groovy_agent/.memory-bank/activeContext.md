# Active Context

**Last updated:** 2026-04-20 (umb + /mmr)

## Current focus

Subagent-driven implementation of `lib/eliza-client/` — a reusable local module extracted from `server.js` and `scripts/test-models.js`.

## Work in progress: Task 7

**Next task to execute:** Task 7 — `chat()` async generator + `chatOnce()` in `lib/eliza-client/index.js` (rev 2: role `developer` for reasoning, no temperature for reasoning, GPT-5 guard → ElizaError 501, usage logging).

Plan file: `docs/superpowers/plans/2026-04-20-eliza-client.md`
Spec file: `docs/superpowers/specs/2026-04-19-eliza-client-design.md` (rev 2 dated 2026-04-20)

## Completed tasks (this session)

- Task 1: `lib/eliza-client/package.json` + stub `index.js` + root `package.json` dep + test script
- Task 2: `lib/eliza-client/models.js` + `test/models.test.js` (14 tests)
- Task 3: `lib/eliza-client/routing.js` + `test/routing.test.js` (24 tests)
- Task 4: `lib/eliza-client/streaming.js` + `test/streaming.test.js` (13 tests)
- Task 5: `lib/eliza-client/probe.js` + `test/probe.test.js` (14 tests)
- Task 6: `lib/eliza-client/index.js` — `createElizaClient` + `getModels` (fetch retries, probe singleton, `onValidated` fallback on probe error, `_sleep`/`_runProbe` test hooks, stubs for `chat`/`chatOnce`/`probe`) + `test/client.test.js` (7 tests)

**Current test count: 72 passing**

## Remaining tasks

- Task 7: `index.js` — add `chat()` async generator + `chatOnce()` (rev 2: role 'developer' for reasoning, no temperature for reasoning, GPT-5 guard → ElizaError 501, usage logging)
- Task 8: Migrate `server.js` — delete ~300 lines, wire eliza-client
- Task 9: Simplify `scripts/test-models.js` → ~30-line CLI wrapper
- Task 10: Update `public/index.html` — `data.pending` → `!data.validated`

## Next step

Implement Task 7 (`chat` / `chatOnce` + tests); see plan file after Task 6 section.

## Sync notes

- **Brain (`/mmr`)**: `brain_save` / `brain_consolidate_dialog` не выполнены — файл `brain.duckdb` заблокирован другим процессом (PID 75425). Повторите `/mmr`, когда лок Brain свободен.

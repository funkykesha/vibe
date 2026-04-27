# Active Context

**Last updated:** 2026-04-26 (umb + mmr)

## Current focus

Tasks 8–10 завершены. `eliza-proxy` создан. Осталось: переключить genidea (Шаг 5 плана).

## Completed this session

- **Task 7**: `chat()` + `chatOnce()` + `probe()` в `lib/eliza-client/index.js`. 77 тестов.
- **A1–A3**: CORS, system passthrough, genidea ↔ groovy_agent интеграция
- **eliza-proxy создан**: `/vibe/eliza-proxy/` — standalone Express-сервис (port 3100), server.js, package.json, CLAUDE.md, lib/eliza-client скопирован, npm install ОК, 77 тестов pass
- **Task 8**: `server.js` переписан — 983 → 452 строки. Inline Eliza-логика удалена, wire eliza-client + createProxyClient (поддержка ELIZA_PROXY_URL)
- **Task 9**: `scripts/test-models.js` упрощён — 782 → 26 строк
- **Task 10**: `public/index.html` — `data.pending` → `!data.validated`
- **eliza-proxy план**: `docs/eliza-proxy-architecture-plan.md`
- **migration plan**: `docs/plans/curried-leaping-steele.md`

## Next steps

- **Шаг 5**: genidea — `AGENT_BASE_URL` → `http://localhost:3100`, путь `/api/chat` → `/v1/chat`, убрать `currentCode`/`inputData` из тела, добавить обработку `usage`

## Pending from external team

- Deploy eliza-proxy + добавить `ELIZA_PROXY_URL=http://localhost:3100` в groovy_agent .env
- genidea team: переключить на `/v1/chat` (Шаг 5)

## Key files

| Файл | Назначение |
|------|-----------|
| `docs/eliza-client-integration-guide.md` | Гайд для внешней команды (текущий и целевой контракт) |
| `docs/eliza-proxy-architecture-plan.md` | План standalone сервиса для команды |
| `genidea/eliza-api-answers.md` | Ответы genidea team на API вопросы |
| `/Users/agaibadulin/.claude/plans/moonlit-drifting-treehouse.md` | План Tasks 7–10 + genidea |

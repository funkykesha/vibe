# Active Context

**Last updated:** 2026-04-26 (umb + mmr)

## Current focus

Архитектурный план `eliza-proxy` готов. Трек A (genidea интеграция) завершён. Tasks 8–10 остались.

## Completed this session

- **Task 7**: `chat()` + `chatOnce()` + `probe()` в `lib/eliza-client/index.js`. 77 тестов.
- **A1–A3**: CORS, system passthrough, genidea ↔ groovy_agent интеграция
- **eliza-proxy план**: `docs/eliza-proxy-architecture-plan.md` — полный план выноса Eliza в standalone сервис для внешней команды. Включает server.js, API, чеклист.
- **genidea/eliza-api-answers.md**: ответы команде genidea на 5 вопросов (usage, pricing, models TTL, rate limits, monitoring, прямой доступ)
- **integration guide (as-is + to-be)**: `docs/eliza-client-integration-guide.md` — практический гайд для внешней команды по интеграции с Eliza Client, включая SDK, текущие `/api/*`, целевые `/v1/*`, SSE контракт и миграционный чеклист.

## Next steps (Трек B — Tasks 8–10)

- **Task 8**: Migrate `server.js` — удалить ~300 строк, wire eliza-client (сохранить passthrough `system`)
- **Task 9**: Упростить `scripts/test-models.js` → ~30-строк CLI wrapper
- **Task 10**: `public/index.html` — `data.pending` → `data.validated === false`

## Pending from external team

- Реализация `eliza-proxy` по плану `docs/eliza-proxy-architecture-plan.md`
- После деплоя: groovy_agent добавляет `ELIZA_PROXY_URL` в .env, genidea меняет `AGENT_BASE_URL` → port 3100 и путь `/v1/chat`

## Key files

| Файл | Назначение |
|------|-----------|
| `docs/eliza-client-integration-guide.md` | Гайд для внешней команды (текущий и целевой контракт) |
| `docs/eliza-proxy-architecture-plan.md` | План standalone сервиса для команды |
| `genidea/eliza-api-answers.md` | Ответы genidea team на API вопросы |
| `/Users/agaibadulin/.claude/plans/moonlit-drifting-treehouse.md` | План Tasks 7–10 + genidea |

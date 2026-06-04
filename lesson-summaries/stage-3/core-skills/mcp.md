# Полное руководство по Claude Code MCP

> Этап 3 · Ключевые навыки

<!-- nav -->
**📚 Версии:** **Кратко** · [Расширенно](../../../lesson-summaries-full/stage-3/core-skills/mcp.md) · [Полный перевод](../../../lesson-originals-ru/stage-3/core-skills/mcp.md) · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-3/core-skills/mcp/index.md)

MCP (Model Context Protocol) подключает Claude Code к внешним инструментам и сервисам: GitHub, базы данных, API, браузер. Урок объясняет настройку, транспорт и практики.

- Конфигурация: пользовательский (`~/.claude.json`) и проектный (`.claude/mcp.json`) уровни.
- Три типа транспорта: STDIO, HTTP, SSE; управление на естественном языке.
- Секреты — в переменные окружения, никогда не хардкодьте ключи.
- Фиксируйте версии серверов; Skills говорят «как», MCP даёт «чем».

# Полное руководство по Claude Agent Teams

> Этап 3 · Ключевые навыки

<!-- nav -->
**📚 Версии:** **Кратко** · [Расширенно](../../../lesson-summaries-full/stage-3/core-skills/agent-teams.md) · [Полный перевод](../../../lesson-originals-ru/stage-3/core-skills/agent-teams.md) · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-3/core-skills/agent-teams/index.md)


Agent Teams позволяет нескольким экземплярам Claude Code работать как настоящая команда: параллельно, общаясь и координируясь. Урок объясняет архитектуру и отличие от Subagent.

- Архитектура: Team Lead, Teammates (свой контекст 200K), TaskList, Messaging.
- Subagent — звёздная топология и раздача задач; Agent Teams — сетевая, настоящая команда.
- Параллельная работа ускоряет крупный рефакторинг примерно на 50%.
- Состояние прозрачно — хранится файлами в `~/.claude/teams/` и `~/.claude/tasks/`.

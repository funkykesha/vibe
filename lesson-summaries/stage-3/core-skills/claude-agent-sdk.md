# Полное руководство по Claude Agent SDK

> Этап 3 · Ключевые навыки

<!-- nav -->
**📚 Версии:** **Кратко** · [Расширенно](../../../lesson-summaries-full/stage-3/core-skills/claude-agent-sdk.md) · [Полный перевод](../../../lesson-originals-ru/stage-3/core-skills/claude-agent-sdk.md) · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-3/core-skills/claude-agent-sdk/index.md)

Claude Agent SDK превращает возможности Claude Code в программируемую библиотеку с автономным выполнением: Claude сам вызывает инструменты, итерирует и проверяет результат.

- Отличие от базового SDK: встроенный agent loop, готовые инструменты, управление контекстом.
- Режимы `query()` (без состояния) и `ClaudeSDKClient` (многораундовый).
- Встроенные инструменты Read/Write/Edit/Bash/Grep и доступ через `allowed_tools`.
- Продвинутое: Hooks, субагенты, MCP; принципы — минимальные права, контроль стоимости.

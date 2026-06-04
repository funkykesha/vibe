# Как разработать расширение для VS Code — создаём AI-помощника по проекту

> Этап 3 · Кроссплатформенная разработка

<!-- nav -->
**📚 Версии:** **Кратко** · [Расширенно](../../../lesson-summaries-full/stage-3/cross-platform/vscode-extension.md) · [Полный перевод](../../../lesson-originals-ru/stage-3/cross-platform/vscode-extension.md) · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-3/cross-platform/vscode-extension/index.md)


Полный цикл создания расширения VS Code «AI Project Bot» — генерация проектов, чат с AI и анализ кода прямо в редакторе.

- package.json через contribution points описывает вклад в редактор, extension.ts — поведение.
- API: TreeView, Chat Participant (@project-bot), Language Model (модель Copilot без своего ключа).
- Создание через Yeoman (yo code), отладка по F5, публикация через vsce.
- context.subscriptions автоматически освобождает ресурсы при деактивации.

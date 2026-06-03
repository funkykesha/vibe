# Как разработать расширение для VS Code — создаём AI-помощника по проекту

> Этап 3 · Кроссплатформенная разработка

Полный цикл создания расширения VS Code «AI Project Bot» — генерация проектов, чат с AI и анализ кода прямо в редакторе.

- package.json через contribution points описывает вклад в редактор, extension.ts — поведение.
- API: TreeView, Chat Participant (@project-bot), Language Model (модель Copilot без своего ключа).
- Создание через Yeoman (yo code), отладка по F5, публикация через vsce.
- context.subscriptions автоматически освобождает ресурсы при деактивации.

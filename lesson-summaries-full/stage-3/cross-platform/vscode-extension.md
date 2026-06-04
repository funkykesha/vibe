# Как разработать расширение для VS Code — создаём AI-помощника по проекту

> Этап 3 · Кроссплатформенная разработка

<!-- nav -->
**📚 Версии:** [Кратко](../../../lesson-summaries/stage-3/cross-platform/vscode-extension.md) · **Расширенно** · [Полный перевод](../../../lesson-originals-ru/stage-3/cross-platform/vscode-extension.md) · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-3/cross-platform/vscode-extension/index.md)


## О чём урок
Урок проводит полный цикл создания расширения VS Code «AI Project Bot» — AI-помощника, который генерирует проекты из шаблонов, ведёт диалог с AI прямо в панели Chat, анализирует выделенный код и связи между несколькими файлами, поддерживает свои горячие клавиши. Показаны разработка, отладка и публикация в Marketplace. Большая часть кода пишется в стиле Vibe Coding через AI-ассистента.

## Ключевые темы
- Архитектура расширения: package.json (манифест и contribution points), extension.ts с функциями activate()/deactivate(), VS Code API, изоляция в процессе Extension Host.
- Создание проекта через Yeoman (yo code), отладка по F5 в окне Extension Development Host, перезагрузка через «Developer: Reload Window».
- TreeView API: боковая панель со списком шаблонов проектов и генерация скелета проекта в один клик.
- Chat Participant API: создание участника `@project-bot` со слэш-командами (/explain, /refactor, /template), потоковый вывод через stream.markdown().
- Language Model API: вызов встроенной модели (например, GPT-4o от Copilot) для анализа кода.
- Контекстные меню редактора и проводника: анализ выделенного кода и связей между несколькими выбранными файлами; кастомные keybindings с when-условиями; индикатор в строке состояния.
- Публикация через vsce: Azure DevOps PAT, Publisher ID, упаковка в .vsix, vsce publish.

## Главные выводы
- package.json через contribution points декларативно описывает, что расширение «вносит» в редактор, а extension.ts реализует поведение.
- Chat Participant API и Language Model API позволяют встроить AI-помощника в редактор, переиспользуя уже установленную модель (Copilot) без своего API-ключа.
- context.subscriptions автоматически освобождает ресурсы при деактивации расширения.
- Та же техника лежит в основе популярных расширений; направления развития — Webview-панели, Language Model Tools, диагностика и CodeLens.

## Инструменты и технологии
- VS Code Extension API, TypeScript, Node.js, Yeoman (generator-code), vsce.
- TreeView API, Chat Participant API, Language Model API, contribution points (commands, menus, keybindings, views).
- GitHub Copilot (источник модели), AI-ассистенты Cursor / Trae / Claude Code, VS Code Marketplace.

# Claude Code Superpowers: разработка инженерного уровня

> Этап 3 · Ключевые навыки

## О чём урок
Superpowers — открытый фреймворк агентских навыков от Джесси Винсента (obra), решающий проблему: как заставить AI писать «инженерный», а не «игрушечный» код. Если обычный AI-помощник — «умный стажёр», то Superpowers даёт ему наставника-сеньора, который заставляет соблюдать полный процесс разработки: прояснение требований, планирование, TDD, код-ревью.

## Ключевые темы
- Проблемы без Superpowers: хаос Vibe Coding, отсутствие дисциплины TDD, работа по размытым требованиям, нестабильное качество.
- Установка через плагин-маркетплейс (`/plugin marketplace add obra/superpowers-marketplace`) или клонирование репозитория.
- 20+ переиспользуемых навыков по категориям: тестирование (`test-driven-development`), отладка (`systematic-debugging`, `verification-before-completion`), сотрудничество (`brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `using-git-worktrees`), код-ревью.
- Три способа срабатывания навыков: по ключевым словам, по сценарию, ручной вызов.
- Стандартный рабочий процесс: Brainstorming → Design Document → Writing Plans → Subagent Development → TDD → Code Review.

## Главные выводы
- Superpowers не делает AI умнее — он делает его дисциплинированным: без навыка TDD Claude пишет тесты «по настроению», с навыком обязан следовать циклу RED-GREEN-REFACTOR.
- Навык `brainstorming` использует сократический метод, заставляя прояснить требования до начала кодирования и не писать лишнего.
- `writing-plans` дробит большую задачу на шаги по 2-5 минут с контрольными точками.
- Подходит для продакшен-кода и долгоподдерживаемых проектов; для быстрых прототипов и одноразовых скриптов полный процесс необязателен.

## Инструменты и технологии
- Superpowers (obra), Claude Code, система плагинов (/plugin)
- Навыки: test-driven-development, systematic-debugging, brainstorming, writing-plans, code-review
- Git worktrees, субагенты, TDD (RED-GREEN-REFACTOR)

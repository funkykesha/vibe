---
title: "Полное руководство по Claude Code MCP"
description: "Узнайте, как использовать Model Context Protocol для подключения внешних инструментов к Claude Code"
---


<!-- nav -->
**📚 Версии:** [Кратко](../../../lesson-summaries/stage-3/core-skills/mcp.md) · [Расширенно](../../../lesson-summaries-full/stage-3/core-skills/mcp.md) · **Полный перевод** · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-3/core-skills/mcp/index.md)

# Claude Code MCP Полное руководство

## Что такое Claude Code MCP?

**Claude Code** — это официальный инструмент командной строки AI от Anthropic, а **MCP (Model Context Protocol)** — это протокол, который позволяет Claude Code подключаться к внешним инструментам и сервисам.

Проще говоря, MCP превращает Claude Code из «AI-помощника, который может только читать и писать локальные файлы» в «суперпомощника, который может обращаться к GitHub, базам данных, API и облачным сервисам»!

## Почему нужно использовать MCP в Claude Code?

### Claude Code без MCP

```
Вы можете делать:
✓ Читать локальные файлы
✓ Редактировать код
✓ Запускать команды
✓ Использовать инструменты Bash

Вы не можете делать:
✗ Просматривать GitHub Issues
✗ Обращаться к облачным базам данных
✗ Вызывать внешние API
✗ Получать данные погоды в реальном времени
```

### Claude Code с MCP

```
Вы можете делать:
✓ Все предыдущие функции
✓ Просматривать/создавать GitHub Issues и PR
✓ Запрашивать базы данных SQLite, PostgreSQL
✓ Обращаться к внешним сервисам (Notion, Slack и т.д.)
✓ Получать данные о погоде, картах в реальном времени
✓ Автоматизация браузера
✓ ...и многое другое!
```

## Быстрый старт

### Шаг 1: Узнайте о расположении файлов конфигурации

Файл конфигурации MCP в Claude Code находится по адресу:

| Уровень | Путь конфигурации | Область действия |
|---------|-------------------|------------------|
| **Пользовательский** | `~/.claude.json` | Все проекты |
| **Уровень проекта** | `.claude/mcp.json` | Текущий проект |

Рекомендуется в первую очередь использовать **конфигурацию уровня проекта**, чтобы разные проекты использовали разные MCP сервисы.

### Шаг 2: Добавьте MCP сервер на естественном языке

В Claude Code вам не нужно вручную редактировать файлы конфигурации или запоминать команды, просто опишите на естественном языке:

```
Вы: Помогите мне добавить GitHub MCP сервер, мой токен — ghp_xxx

Claude: Я помогу вам настроить GitHub MCP сервер...

[Автоматическое обновление .claude/mcp.json]
```

```
Вы: Добавьте SQLite сервер баз данных, файл базы данных находится в ./data/app.db

Claude: Хорошо, я настрою SQLite MCP сервер...
```

```
Вы: Добавьте HTTP MCP сервер, адрес https://api.example.com/mcp

Claude: Я добавлю этот удаленный MCP сервер...
```

### Шаг 3: Проверьте конфигурацию

Спросите Claude Code напрямую:

```
Вы: Какие MCP сервисы сейчас доступны?

Claude: Сейчас настроены следующие MCP сервисы:
• github - Интеграция GitHub
• sqlite - База данных SQLite
• filesystem - Доступ к файловой системе
```

Или используйте диагностическую команду:

```
/doctor
```

### Шаг 4: Начните использовать

После успешной конфигурации просто используйте MCP функции на естественном языке:

```
Вы: Помогите мне создать Issue на GitHub

Claude: Я могу создать GitHub Issue. Пожалуйста, скажите мне:
- Адрес репозитория (например, owner/repo)
- Название Issue
- Описание Issue
```

## Управление MCP сервисами с естественным языком

### Просмотр и управление MCP сервисами

Вы можете полностью взаимодействовать с Claude Code на естественном языке:

```
Вы: Покажите все настроенные MCP сервисы

Вы: Проверьте статус подключения MCP сервисов

Вы: Удалите MCP сервер notion

Вы: Обновите токен для сервера github
```

### Диагностика проблем

Когда возникают проблемы:

```
Вы: Я не могу подключиться к MCP серверу, помогите проверить

Claude: [Автоматически запустит диагностику, проанализирует конфигурационные файлы, проверит статус сервера]
```

## Подробное описание способов конфигурации

### Конфигурация уровня пользователя (глобальная)

Отредактируйте `~/.claude.json`:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/yourname/Documents"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your-token"
      }
    }
  }
}
```

### Конфигурация уровня проекта (рекомендуется)

Отредактируйте `.claude/mcp.json` в корневом каталоге проекта:

```json
{
  "mcpServers": {
    "project-db": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sqlite", "--db-path", "./data/app.db"]
    }
  }
}
```

**Преимущества конфигурации уровня проекта:**
- Члены команды могут делиться конфигурацией (отправлять в Git)
- Разные проекты используют разные MCP сервисы
- Конфигурация более гибкая, не загрязняет глобальные настройки

### Конфигурация способов передачи

Claude Code поддерживает три способа передачи:

#### STDIO (локальный процесс)

```json
{
  "mcpServers": {
    "local-tool": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path"]
    }
  }
}
```

#### HTTP (удаленный сервис)

```json
{
  "mcpServers": {
    "remote-api": {
      "url": "https://api.example.com/mcp",
      "transport": "http",
      "headers": {
        "Authorization": "Bearer your-token"
      }
    }
  }
}
```

#### SSE (server-sent events)

```json
{
  "mcpServers": {
    "streaming": {
      "url": "https://api.example.com/sse",
      "transport": "sse"
    }
  }
}
```

## Примеры практического использования

### Пример 1: Автоматизация рабочего процесса GitHub

```
Вы: Помогите мне отправить текущие изменения на GitHub, затем создать PR с названием «Добавить новую функцию»

Claude:
1. Проверяю статус git...
2. Создаю новую ветку feature/new-feature...
3. Фиксирую изменения...
4. Отправляю в удаленный репозиторий...
5. Вызываю github_create_pull_request для создания PR...
6. PR создан: https://github.com/owner/repo/pull/123
```

### Пример 2: Запрос к базе данных

```
Вы: Запросите из базы данных 10 последних зарегистрировавшихся пользователей

Claude:
1. Подключаюсь к базе данных SQLite...
2. Выполняю запрос: SELECT * FROM users ORDER BY created_at DESC LIMIT 10
3. Возвращаю результат:
   - Иван Петров (ivan@example.com) - 2025-02-28
   - Мария Сидорова (maria@example.com) - 2025-02-27
   ...
```

### Пример 3: Скриншот веб-страницы и анализ

```
Вы: Откройте https://example.com и сделайте скриншот, проанализируйте дизайн страницы

Claude:
1. Запускаю браузер...
2. Переходу на https://example.com...
3. Делаю скриншот...
4. [Возвращаю скриншот]
5. Анализ дизайна страницы:
   - Макет использует центрированный дизайн, максимальная ширина 1200px
   - Основной цвет — синий (#3b82f6)
   - Навигационная панель закреплена в верхней части
   ...
```

### Пример 4: Интеграция с Notion

```
Вы: Сохраните мои заметки в Notion

Claude:
1. Использую Notion MCP сервер...
2. Создаю новую страницу...
3. Сохранено: https://notion.so/page/xxx
```

## Советы по отладке

### Используйте естественный язык для диагностики

Когда возникают проблемы, просто скажите Claude Code:

```
Вы: Мой MCP сервер не подключается, помогите проверить

Вы: Ошибка инструмента GitHub MCP, в чем причина?

Вы: Почему сервер sqlite постоянно показывает состояние подключения?
```

Claude Code автоматически:
1. Проверит формат конфигурационного файла
2. Проверит переменные окружения
3. Протестирует подключение к серверу
4. Предоставит конкретные рекомендации по исправлению

### Устранение неполадок часто встречающихся проблем

| Проблема | Возможная причина | Решение |
|---------|-------------------|---------|
| Сервер не подключен | Неправильный формат конфигурации | Проверьте синтаксис JSON |
| Инструмент не вызывается | Недостаточно разрешений | Проверьте переменные окружения |
| Превышено время подключения | Проблемы с сетью | Проверьте URL или сетевое соединение |
| Процесс упал | Ошибка в коде сервера | Посмотрите логи сервера |

### Команда ручной диагностики

```
/doctor
```

Пример вывода:
```
Отчет о системной диагностике:
===============

Claude Code: v2.5.0 ✓
Node.js: v20.0.0 ✓

Статус MCP сервисов:
• github: ✓ Подключен (12 инструментов)
• sqlite: ✗ Ошибка подключения - Database file not found
• puppeteer: ✓ Подключен (8 инструментов)

Рекомендации:
1. Проверьте правильность пути к базе данных sqlite
2. Убедитесь, что формат .claude/mcp.json правильный
```

## Лучшие практики

### 1. Конфигурация уровня проекта приоритетная

**Почему рекомендуется конфигурация уровня проекта?**

Разные проекты часто требуют разных MCP сервисов. Например, фронтенд проект может нуждаться в инструментах для тестирования браузера, а бэкенд проект — в подключении к базе данных. Конфигурация уровня проекта позволяет каждому проекту иметь собственный набор MCP сервисов, избегая беспорядка в глобальной конфигурации.

Более важно то, что конфигурация уровня проекта может быть отправлена в репозиторий Git. Когда члены команды клонируют проект, они могут сразу использовать те же MCP сервисы без необходимости повторной конфигурации.

```
Проект A (фронтенд) → .claude/mcp.json содержит MCP браузерного тестирования
Проект B (бэкенд) → .claude/mcp.json содержит MCP базы данных
```

### 2. Переменные окружения для конфиденциальной информации

**Никогда не жестко кодируйте ключи в конфигурационные файлы!**

Конфигурационные файлы могут быть случайно отправлены в репозиторий Git, что приведет к утечке ключей. Правильный подход — хранить конфиденциальную информацию в переменных окружения, а конфигурационный файл только ссылается на имена переменных. Таким образом, даже если конфигурационный файл будет опубликован, фактические ключи не будут раскрыты.

```json
{
  "env": {
    "GITHUB_TOKEN": "$GITHUB_TOKEN",  // ✓ Хорошо - читаем из переменной окружения
    "GITHUB_TOKEN": "ghp_abc123"       // ✗ Плохо - жестко кодированный ключ
  }
}
```

### 3. Блокировка версии

**Почему нужна блокировка версии?**

По умолчанию `npx -y` всегда использует последнюю версию MCP сервера. Это может привести к проблемам: новая версия может содержать несовместимые изменения, или какой-то сервер может быть неожиданно удален или переименован.

Добавляя `@версия` после имени пакета, вы гарантируете, что всегда используется проверенная конкретная версия, избегая неожиданных проблем из-за автоматического обновления.

```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github@1.2.3"]  // Зафиксированная версия
}
```

### 4. Документирование конфигурации MCP

**Помогите членам команды быстро разобраться в конфигурации MCP**

Когда в проекте несколько MCP сервисов, новые члены команды могут не понимать назначение каждого сервера и требования к конфигурации. Создание файла `README.md` в директории `.claude/`, объясняющего назначение каждого сервера, необходимые элементы конфигурации и способы получения, может значительно снизить затраты на общение в команде.

Создайте `.claude/README.md` в проекте:

```markdown
# Конфигурация MCP

Используемые в этом проекте MCP сервисы:

## github
Для автоматизации операций GitHub требуется конфигурация GITHUB_TOKEN.

## sqlite
Подключение к ./data/app.db для запросов и модификации данных.

## puppeteer
Используется для E2E тестирования.
```

## Claude Code vs Claude Desktop

| Функция | Claude Code | Claude Desktop |
|---------|-------------|----------------|
| **Конфигурационный файл** | `~/.claude.json` или `.claude/mcp.json` | `claude_desktop_config.json` |
| **Конфигурация уровня проекта** | ✓ Поддерживается | ✗ Не поддерживается |
| **Управление естественным языком** | ✓ Поддерживается | ✗ Нужно редактировать вручную |
| **Инструмент диагностики** | ✓ `/doctor` | ✗ Нет |
| **Горячая перезагрузка** | ✓ Автоматическая перезагрузка | ✗ Нужен перезапуск приложения |
| **Сценарии использования** | Рабочий процесс разработки, CI/CD | Повседневное использование, офис |

## Часто используемые MCP сервисы

> 💡 Полный список MCP сервисов см. в приложении [Справочник MCP сервисов](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/appendix/mcp-servers/index.md)

### GitHub сервер

**Функция:** Issues, PR, управление репозиторием

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your-token"
      }
    }
  }
}
```

**Получить токен:** https://github.com/settings/tokens

### SQLite сервер

**Функция:** Запросы и управление базами данных SQLite

```json
{
  "mcpServers": {
    "sqlite": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sqlite", "--db-path", "./data/database.db"]
    }
  }
}
```

### Сервер файловой системы

**Функция:** Доступ к файлам в определенной директории

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/yourname/Documents"]
    }
  }
}
```

### Puppeteer браузер автоматизация

**Функция:** Управление браузером, скриншоты, автоматизация тестирования

```json
{
  "mcpServers": {
    "puppeteer": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-puppeteer"]
    }
  }
}
```

### Brave поиск сервер

**Функция:** Веб поиск

```json
{
  "mcpServers": {
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "your-brave-api-key"
      }
    }
  }
}
```

## Справочные материалы

### Официальная документация

- [Claude Code официальная документация - MCP](https://docs.anthropic.com/zh-CN/docs/claude-code/mcp)
- [MCP официальный сайт](https://modelcontextprotocol.io/)
- [Документация спецификации MCP](https://modelcontextprotocol.io/specification/)
- [GitHub репозиторий MCP](https://github.com/modelcontextprotocol)

### Официальные сервисы

- [@modelcontextprotocol/server-github](https://github.com/modelcontextprotocol/servers/tree/main/src/github) - Интеграция GitHub
- [@modelcontextprotocol/server-sqlite](https://github.com/modelcontextprotocol/servers/tree/main/src/sqlite) - База данных SQLite
- [@modelcontextprotocol/server-postgres](https://github.com/modelcontextprotocol/servers/tree/main/src/postgres) - База данных PostgreSQL
- [@modelcontextprotocol/server-filesystem](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem) - Доступ к файловой системе
- [@modelcontextprotocol/server-puppeteer](https://github.com/modelcontextprotocol/servers/tree/main/src/puppeteer) - Браузер автоматизация
- [@modelcontextprotocol/server-fetch](https://github.com/modelcontextprotocol/servers/tree/main/src/fetch) - Скрепинг веб сайтов
- [@modelcontextprotocol/server-brave-search](https://github.com/modelcontextprotocol/servers/tree/main/src/brave-search) - Поиск Brave
- [@modelcontextprotocol/server-git](https://github.com/modelcontextprotocol/servers/tree/main/src/git) - Git операции

### Статьи и учебники

- [Полное объяснение принципов и практики MCP](https://view.inews.qq.com/a/20250414A023WV00)
- [Архитектура MCP (Model Context Protocol) и принцип работы](https://m.toutiao.com/w/1826385835060307/)
- [2025 Новейший учебник по большим языковым моделям: от основ MCP к мастерству](https://m.blog.csdn.net/weixin_45653328/article/details/150916706)
- [Учитесь MCP с нуля (восьмой) - Построение MCP сервера](https://juejin.cn/post/7582510291667419187)

### Руководства по конфигурации

- [Claude Code лучшие практики](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Полное руководство по конфигурации Claude Code](https://juejin.cn/post/7576838552472043563)

### Учебники по разработке

- [Руководство по построению MCP сервера на TypeScript/Python с нуля](https://m.blog.csdn.net/ztt123654/article/details/150844207)
- [Полное руководство по построению MCP сервера: полный учебник TypeScript и Python двойной версии](https://m.blog.csdn.net/gitblog_00703/article/details/154862128)
- [Построение простейшего MCP сервера на TypeScript](https://m.blog.csdn.net/weixin_45653525/article/details/148433757)
- [Построение MCP сервера TypeScript с использованием контейнерных приложений Azure](https://learn.microsoft.com/zh-cn/azure/developer/ai/build-mcp-server-ts)

### Ресурсы MCP сервисов

- [Awesome MCP Servers](https://github.com/punkpeye/awesome-mcp-servers) - Наиболее полный список MCP сервисов
- [Official MCP Registry](https://registry.modelcontextprotocol.io) - Официальный «app store» Anthropic
- [MCP.so](https://mcp.so) - Центр MCP сервисов сообщества
- [Glama.ai MCP](https://glama.ai/mcp/servers) - Каталог MCP с рейтингами и отзывами
- [Smithery](https://smithery.ai) - Маркетплейс MCP сервисов
- [MCPHub](https://mcphub.io/registry) - Каталог с простым интерфейсом
- [LobeHub MCP](https://lobehub.com/zh/mcp) - Китайский каталог MCP

### Сервисы карт и погоды

- [Amap MCP Server](https://lobehub.com/zh/mcp/luozengchang-mcp-amap)
- [Документация Tencent Location Service MCP](https://lbs.qq.com/service/MCPServer/MCPServerGuide/overview)
- [Caiyun Weather MCP Server](https://github.com/caiyunapp/mcp-caiyun-weather)
- [OpenWeatherMap MCP Server](https://github.com/CodeByWaqas/weather-mcp-server)

### Ресурсы сообщества

- [Everything Claude Code Config](https://github.com/affaan-m/everything-claude-code) - Набор конфигураций Claude Code производственного уровня
- [AI Coding Guide](https://github.com/hacket/AICodingGuide) - Путь обучения Claude Code на китайском языке

### Практические примеры использования

- [BlenderMCP - AI управляемое трехмерное моделирование](https://github.com/Belthur/blender-mcp) - 4,100+ звезд
- [MCP в производстве 15 лучших практик](https://learn.microsoft.com/zh-cn/azure/azure-functions/scenario-mcp-apps)

---
title: Полный гайд Claude Agent SDK
description: Как использовать Agent SDK для автономного выполнения задач разработки
---


<!-- nav -->
**📚 Версии:** [Кратко](../../../lesson-summaries/stage-3/core-skills/claude-agent-sdk.md) · [Расширенно](../../../lesson-summaries-full/stage-3/core-skills/claude-agent-sdk.md) · **Полный перевод** · [Оригинал 中文](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/stage-3/core-skills/claude-agent-sdk/index.md)

# Claude Agent SDK Полный гайд

## Введение

Вы, вероятно, уже использовали базовый Claude API — отправляете сообщение, получаете ответ, как чат. Но если вы хотите, чтобы Claude помогал вам читать файлы, запускать команды, искать код, исправлять баги, потом проверять результаты, потом продолжать исправлять — такое "самостоятельное работание", базовый API это не может.

Claude Agent SDK созданный для этого сценария. Он упаковал все возможности Claude Code — чтение/запись файлов, выполнение команд, поиск кода, редактирование файлов, просмотр веб-сайтов — в программируемую библиотеку. Вам не нужно самим писать цикл обработки вызовов инструментов, Claude будет самостоятельно выполнять инструменты, самостоятельно итерировать, пока задача действительно не завершится.

Одна фраза резюме: базовый SDK это "вы спрашиваете, оно отвечает", Agent SDK это "вы даёте приказ, оно работает".

---

## Чем это отличается от базового SDK?

Сначала смотрите код, видно сразу:

```python
# Базовый anthropic SDK: нужно самим писать цикл обработки вызовов инструментов
import anthropic

client = anthropic.Anthropic()
response = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    messages=[{"role": "user", "content": "исправьте bug в auth.py"}],
    tools=[...]  # нужно самим определить инструменты
)
# Claude говорит нужно вызвать какой-то инструмент
while response.stop_reason == "tool_use":
    result = your_tool_executor(response.tool_use)  # нужно самим выполнить
    response = client.messages.create(tool_result=result, **params)  # нужно самим закормить результат
```

```python
# Agent SDK: одна строка, Claude самостоятельно читает файлы, находит bug, меняет код
from claude_agent_sdk import query, ClaudeAgentOptions

async for message in query(
    prompt="исправьте bug в auth.py",
    options=ClaudeAgentOptions(allowed_tools=["Read", "Edit", "Bash"]),
):
    print(message)  # Claude самостоятельно читает файлы, отыскивает проблему, меняет код
```

Различие очень явное:

| Пункт сравнения | Базовый anthropic SDK | Claude Agent SDK |
|--------|-------------------|-----------------|
| Выполнение инструментов | Нужно самим писать | Claude самостоятельно |
| Цикл инструментов | Нужно самим реализовать | Встроен в agent loop |
| Встроенные инструменты | Нет, полностью нужно определить | Чтение/запись файлов, Bash, поиск и т.д. из коробки |
| Управление контекстом | Нужно самим содержать | Автоматическое сжатие и управление |
| Подходящие сценарии | Чат, генерация, простой tool use | Автономное завершение сложных задач |

---

## Чем это отличается от других фреймворков Agent?

На рынке много фреймворков Agent — LangChain, LlamaIndex, CrewAI, AutoGPT… Claude Agent SDK сравнить с ними что уникального?

> 📚 **Подробное сравнение см. в приложении**: [Сравнение основных фреймворков Agent](https://github.com/datawhalechina/easy-vibe/blob/main/docs/zh-cn/appendix/8-artificial-intelligence/ai-agents/index.md)

Просто говоря:

| Фреймворк | Самый подходящий сценарий |
|------|-------------|
| **Claude Agent SDK** | Позволить Claude автономно завершить разработку кода, операции с файлами, выполнение команд |
| **LangChain** | Построить сложное универсальное AI приложение, нужна высокая степень кастомизации процесса |
| **CrewAI** | Имитировать многоролевое сотрудничество (такое как виртуальная команда, ролевое отыгрывание) |
| **LlamaIndex** | Построить систему вопросов-ответов базы знаний, подключить корпоративные данные к LLM |

---

## Установка и конфигурация

### Установка

Python требует 3.10+, TypeScript требует Node.js 18+:

```bash
# Python
pip install claude-agent-sdk

# TypeScript
npm install @anthropic-ai/claude-agent-sdk
```

### Аутентификация

Установить переменную окружения API Key:

```bash
export ANTHROPIC_API_KEY=your-api-key
```

Также поддерживается облачная платформа аутентификация:
- AWS Bedrock: установить `CLAUDE_CODE_USE_BEDROCK=1` + AWS учётные данные
- Google Vertex AI: установить `CLAUDE_CODE_USE_VERTEX=1` + GCP учётные данные
- Microsoft Azure: установить `CLAUDE_CODE_USE_FOUNDRY=1` + Azure учётные данные

### Пользовательский адрес API

Если вы используете прокси, шлюз или самостоятельный API адрес, можно через параметр `env` изменить URL API по умолчанию:

```python
from claude_agent_sdk import query, ClaudeAgentOptions

async for message in query(
    prompt="Привет",
    options=ClaudeAgentOptions(
        env={
            "ANTHROPIC_BASE_URL": "https://your-proxy.example.com",
            "ANTHROPIC_API_KEY": "your-api-key",
        }
    ),
):
    print(message)
```

`ClaudeAgentOptions` не имеет прямого параметра `base_url`, но поле `env` может передать любую переменную окружения в базовый Claude Code CLI. Часто используемые переменные окружения:

| Переменная окружения | Назначение |
|---------|------|
| `ANTHROPIC_BASE_URL` | Пользовательский API адрес (прокси, шлюз) |
| `ANTHROPIC_API_KEY` | API ключ |
| `ANTHROPIC_AUTH_TOKEN` | Альтернативный токен аутентификации |
| `ANTHROPIC_CUSTOM_HEADERS` | Пользовательские заголовки запросов |

---

## Основные концепции

Принцип работы Agent SDK можно описать одной фразой: **собрать контекст → выполнить действие → проверить результат → повторить**.

Это точно как работают люди разработчики — сначала смотреть код, потом менять код, потом запускать тесты смотреть результат, не подходит продолжить менять. Agent SDK автоматизировал этот цикл.

### Два режима использования

**Режим первый: функция `query()` — без состояния, подходит для одиночных задач**

```python
import asyncio
from claude_agent_sdk import query, ClaudeAgentOptions

async def main():
    async for message in query(
        prompt="какие файлы в этой директории?",
        options=ClaudeAgentOptions(allowed_tools=["Bash", "Glob"]),
    ):
        if hasattr(message, "result"):
            print(message.result)

asyncio.run(main())
```

**Режим второй: `ClaudeSDKClient` — с состоянием, подходит для многораундных диалогов**

Когда нужно сохранять контекст, многораундное взаимодействие. Например сначала позволить Claude прочитать модуль, потом позволить ему найти все места где вызывается этот модуль — во втором раунде оно помнит что прочитало в первом раунде.

```python
import asyncio
from claude_agent_sdk import query, ClaudeAgentOptions

async def main():
    session_id = None

    # Первый раунд: читать модуль аутентификации
    async for message in query(
        prompt="прочитать код модуля аутентификации",
        options=ClaudeAgentOptions(allowed_tools=["Read", "Glob"]),
    ):
        if hasattr(message, "subtype") and message.subtype == "init":
            session_id = message.session_id

    # Второй раунд: на основе контекста продолжить работать
    async for message in query(
        prompt="найти все места где вызывается этот модуль",
        options=ClaudeAgentOptions(resume=session_id),
    ):
        if hasattr(message, "result"):
            print(message.result)

asyncio.run(main())
```

---

## Встроенные инструменты: используй из коробки

Это самое приятное в Agent SDK — не нужно самим реализовать никакие инструменты, Claude прямо может их использовать:

| Инструмент | Функция | Типичное использование |
|------|------|---------|
| Read | Чтение файлов | Смотреть код, читать конфиг |
| Write | Создание файлов | Генерировать новые файлы |
| Edit | Точное редактирование файлов | Исправлять баги, рефакторить |
| Bash | Выполнение терминальных команд | Запускать тесты, устанавливать зависимости, git операции |
| Glob | Найти файлы по шаблону | `**/*.py`, `src/**/*.ts` |
| Grep | Поиск по файлам с помощью regex | Найти определение функции, найти TODO |
| WebSearch | Поиск в интернете | Смотреть документацию, найти решение |
| WebFetch | Получить содержимое веб-страницы | Читать онлайн документацию |
| Task | Запустить sub agent | Параллельная обработка подзадач |

Через параметр `allowed_tools` контролируете какие инструменты может использовать agent:

```python
# Agent только для чтения: может смотреть, не может менять
options = ClaudeAgentOptions(
    allowed_tools=["Read", "Glob", "Grep"],
    permission_mode="bypassPermissions"
)

# Полномощный agent: может читать, писать, запускать команды
options = ClaudeAgentOptions(
    allowed_tools=["Read", "Write", "Edit", "Bash", "Glob", "Grep"]
)
```

---

## Продвинутые функции

### Hooks: вставьте свою логику в ключевые моменты

Hooks позволяют вставить пользовательский код в ключевые моменты выполнения agent — например записывать логи, перехватывать опасные операции, аудировать изменения файлов.

Поддерживаемые типы Hook: `PreToolUse` (до выполнения инструмента), `PostToolUse` (после выполнения инструмента), `Stop` (когда agent остановится), `SessionStart`, `SessionEnd` и т.д.

```python
from datetime import datetime
from claude_agent_sdk import query, ClaudeAgentOptions, HookMatcher

# Каждый раз когда файл меняется, записать в лог аудита
async def log_file_change(input_data, tool_use_id, context):
    file_path = input_data.get("tool_input", {}).get("file_path", "unknown")
    with open("./audit.log", "a") as f:
        f.write(f"{datetime.now()}: modified {file_path}\n")
    return {}

async def main():
    async for message in query(
        prompt="рефакторить utils.py повышая читаемость",
        options=ClaudeAgentOptions(
            permission_mode="acceptEdits",
            hooks={
                "PostToolUse": [
                    HookMatcher(matcher="Edit|Write", hooks=[log_file_change])
                ]
            },
        ),
    ):
        if hasattr(message, "result"):
            print(message.result)
```

Практическое использование:
- Лог аудита: записывать каждый шаг agent
- Безопасность перехват: блокировать agent от изменения некоторых критичных файлов
- Уведомление: отправлять уведомление когда agent завершит задачу
- Мониторинг стоимости: статистика вызовов инструментов и потребления токенов

### Sub Agent: отдать большие задачи специалистам

Когда задача достаточно сложная, можно определить несколько специализированных sub agent, позволить главному agent распределять подзадачи между ними. Каждый sub agent имеет свои инструкции и권限 инструментов, не мешают друг другу.

```python
from claude_agent_sdk import query, ClaudeAgentOptions, AgentDefinition

async for message in query(
    prompt="используй code-reviewer agent проверить качество кода этого проекта",
    options=ClaudeAgentOptions(
        allowed_tools=["Read", "Glob", "Grep", "Task"],
        agents={
            "code-reviewer": AgentDefinition(
                description="Профессиональный code reviewer, отвечает за качество и безопасность",
                prompt="Анализировать качество кода, найти потенциальные проблемы и дать рекомендации улучшения.",
                tools=["Read", "Glob", "Grep"],
            ),
            "test-writer": AgentDefinition(
                description="Эксперт по тестированию, отвечает за написание unit тестов",
                prompt="Для функций без тестов написать unit тесты.",
                tools=["Read", "Write", "Bash"],
            ),
        },
    ),
):
    if hasattr(message, "result"):
        print(message.result)
```

Сообщения sub agent будут содержать поле `parent_tool_use_id`, удобно для отслеживания какие сообщения откуда пришли.

### MCP интеграция: подключить внешний мир

Через Model Context Protocol (MCP), ваш agent может подключиться к базам данных, браузерам, внешним API и другим внешним системам. Сообщество уже имеет [сотни MCP серверов](https://github.com/modelcontextprotocol/servers) которые можно прямо использовать.

```python
# Подключить Playwright, позволить agent операции в браузере
async for message in query(
    prompt="открыть example.com и описать что видишь",
    options=ClaudeAgentOptions(
        mcp_servers={
            "playwright": {
                "command": "npx",
                "args": ["@playwright/mcp@latest"]
            }
        }
    ),
):
    if hasattr(message, "result"):
        print(message.result)
```

Типичные сценарии MCP интеграции:
- Playwright: автоматизация браузера, скрепинг веб-страниц, заполнение форм
- PostgreSQL/MySQL: прямой запрос и операции в БД
- Slack/Email: отправка уведомлений и сообщений
- GitHub: операции с PR, Issue, репозитории кода

---

## Что можно делать? Практические сценарии

После понимания функций, самый важный вопрос: это может делать что? Ниже реальные сценарии которые проверены сообществом.

### Сценарий первый: Agent автоматического исправления Bug

Дай описание bug, оно самостоятельно найти код, определить проблему, исправить, запустить тесты проверить:

```python
async for message in query(
    prompt="пользователи сообщили что при входе иногда выбросится ошибка 500, проверить код в директории src/auth/ и исправить",
    options=ClaudeAgentOptions(
        allowed_tools=["Read", "Edit", "Bash", "Glob", "Grep"],
        permission_mode="acceptEdits",
    ),
):
    print(message)
```

Claude самостоятельно будет grep ошибки в логах, читать соответствующий код, найти bug, менять код, запускать тесты подтверждение что исправлено.

### Сценарий второй: Code Review Agent

Построить agent только для чтения для code review, проверять качество кода но не делать никаких изменений:

```python
async for message in query(
    prompt="проверить код в директории src/, обратить внимание на уязвимости безопасности, проблемы производительности и нарушение стандартов",
    options=ClaudeAgentOptions(
        allowed_tools=["Read", "Glob", "Grep"],
        permission_mode="bypassPermissions",
    ),
):
    if hasattr(message, "result"):
        print(message.result)
```

### Сценарий третий: Интеграция CI/CD

В конвейере непрерывной интеграции, позволить agent автоматически анализировать падающие тесты и пытаться исправить:

```python
async for message in query(
    prompt="запустить npm test, анализировать падающие тесты, исправить код чтобы все тесты прошли",
    options=ClaudeAgentOptions(
        allowed_tools=["Read", "Edit", "Bash", "Glob"],
        max_turns=20,
    ),
):
    print(message)
```

Это самое большое преимущество Agent SDK по сравнению с CLI — CLI подходит для человека сидящего перед терминалом interacting, SDK подходит для встраивания в автоматизированные процессы.

### Сценарий четвёртый: Research Agent

Позволить agent искать в интернете, читать документацию, синтезировать информацию и выводить отчёт:

```python
async for message in query(
    prompt="исследовать основные Python Web фреймворки 2026 года, сравнить FastAPI, Django, Litestar, выводить tech selection отчёт в report.md",
    options=ClaudeAgentOptions(
        allowed_tools=["WebSearch", "WebFetch", "Write"],
    ),
):
    print(message)
```

### Сценарий пятый: Полнопроектный Agent с браузером

Через MCP подключить Playwright, agent не только может писать код, может открыть браузер проверить эффект:

```python
async for message in query(
    prompt="исправить проблемы стиля на главной странице, потом открыть браузер скриншот проверить эффект",
    options=ClaudeAgentOptions(
        allowed_tools=["Read", "Edit", "Bash"],
        mcp_servers={
            "playwright": {
                "command": "npx",
                "args": ["@playwright/mcp@latest"]
            }
        },
    ),
):
    print(message)
```

### Таблица быстрого просмотра сценариев

| Сценарий | Основные инструменты | Сложность |
|------|---------|------|
| Автоматическое исправление Bug | Read, Edit, Bash, Grep | Начальная |
| Code review | Read, Glob, Grep | Начальная |
| CI/CD автоматическое исправление | Read, Edit, Bash | Средняя |
| Техническое исследование отчёт | WebSearch, WebFetch, Write | Начальная |
| Автоматизация браузера | MCP (Playwright) | Средняя |
| Многоагентское сотрудничество | Task + AgentDefinition | Продвинутая |
| Операции с БД | MCP (PostgreSQL/MySQL) | Средняя |
| Email/уведомлений помощник | MCP (Slack/Email) | Средняя |

---

## Когда использовать Agent SDK?

Не все сценарии подходят для Agent SDK. Выбрать правильный инструмент очень важно:

| Вы хотите сделать | Нужно использовать что |
|-----------|---------|
| Простой диалог, текстовая генерация, перевод | Базовый `anthropic` SDK |
| Одиночный tool use (проверить погоду, вычислить) | Базовый `anthropic` SDK |
| Автономно завершить многошаговую задачу разработки | Agent SDK |
| Встроить в CI/CD конвейер | Agent SDK |
| Построить приложение которое может операции в файловой системе | Agent SDK |
| Дневной interactive разработка | Claude Code CLI |
| Разовая быстрая задача | Claude Code CLI |

Просто: если ваша задача требует Claude "самому рукава работать" (читать файлы, менять код, запускать команды), используйте Agent SDK. Если только "вопрос-ответ", базовый SDK достаточно.

---

## Энтерпрайз уровень практика: построить pipeline хранения качества кода

Ранние сценарии это одиночный agent делает одну работу. Но в настоящем энтерпрайзе окружении, нужна полная pipeline — несколько agent в серии сотрудничают, каждый этап имеет чёткий ввод вывод, есть аудит, откат, уведомление.

Ниже мы построим настоящий сценарий: **после PR отправки, автоматически запустить code review → security scan → автоматическое исправление → тестирование → генерация отчёта** полная pipeline.

### Дизайн архитектуры

```
Отправка PR
  │
  ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Code Review │───▶│ Security Scan │───▶│ Auto Fix    │
│  Agent       │    │ Agent        │    │ Agent       │
│ (read-only)  │    │ (read-only)   │    │ (write)     │
└─────────────┘    └─────────────┘    └─────────────┘
                                            │
                                            ▼
                                     ┌─────────────┐    ┌─────────────┐
                                     │ Test Verify │───▶│ Report Gen  │
                                     │ Agent       │    │ Agent       │
                                     │ (Bash)      │    │ (Write)     │
                                     └─────────────┘    └─────────────┘
                                                              │
                                                              ▼
                                                        Slack уведомление
```

Основная идея: **каждый agent делает одну вещь,권한최소화, результаты в цепочку передаются**.

### Первый этап: определить framework pipeline

```python
import asyncio
import json
from datetime import datetime
from claude_agent_sdk import query, ClaudeAgentOptions, HookMatcher

# Лог аудита: записывать каждый шаг agent
audit_log = []

async def audit_hook(input_data, tool_use_id, context):
    audit_log.append({
        "time": datetime.now().isoformat(),
        "tool": input_data.get("tool_name"),
        "input": input_data.get("tool_input", {}),
    })
    return {}

# Универсальная конфиг hook: все agent разделяют аудит способность
audit_hooks = {
    "PostToolUse": [HookMatcher(matcher=".*", hooks=[audit_hook])]
}
```

### Второй этап: Code Review Agent (только для чтения)

```python
async def run_code_review(pr_diff: str) -> str:
    """Только для чтения agent, проверить качество кода, выводить структурированный отчёт"""
    result_text = ""
    async for message in query(
        prompt=f"""Проверить следующий PR diff, анализировать с нескольких сторон:
1. Качество кода: имена, формат, комментарии
2. Логические проблемы: граничные случаи, null pointers, race condition
3. Производительность: N+1 queries, утечки памяти, ненужные циклы
4. Содержание: слишком длинные функции, неясная ответственность, магические числа

PR Diff:
{pr_diff}

Выводить JSON формат: {{"issues": [{{"severity": "high/medium/low", "file": "...", "line": ..., "description": "..."}}], "summary": "..."}}""",
        options=ClaudeAgentOptions(
            allowed_tools=["Read", "Glob", "Grep"],
            permission_mode="bypassPermissions",
            hooks=audit_hooks,
            max_turns=10,
        ),
    ):
        if hasattr(message, "result"):
            result_text = message.result
    return result_text
```

### Третий этап: Security Scan Agent (только для чтения)

```python
async def run_security_scan() -> str:
    """Только для чтения agent, focus на security уязвимости сканирование"""
    result_text = ""
    async for message in query(
        prompt="""Сканировать код проекта на security уязвимости:
1. SQL injection, XSS, CSRF
2. Хардкодированные ключи или credentials
3. Небезопасные версии зависимостей
4. Отсутствие проверок권限

Выводить JSON: {{"vulnerabilities": [{{"severity": "critical/high/medium", "type": "...", "file": "...", "description": "...", "fix_suggestion": "..."}}]}}""",
        options=ClaudeAgentOptions(
            allowed_tools=["Read", "Glob", "Grep", "Bash"],
            permission_mode="bypassPermissions",
            hooks=audit_hooks,
            max_turns=15,
        ),
    ):
        if hasattr(message, "result"):
            result_text = message.result
    return result_text
```

### Четвёртый этап: Auto Fix Agent (может писать)

```python
async def run_auto_fix(review_result: str, security_result: str) -> str:
    """Может писать agent, по результатам проверки автоматически исправить код"""
    result_text = ""
    async for message in query(
        prompt=f"""На основе результатов проверки исправить код:

Отчёт code review:
{review_result}

Отчёт security сканирования:
{security_result}

Правила исправления:
1. Исправлять только проблемы severity high или critical
2. После каждого изменения запускать соответствующие тесты подтверждение что не сломано существующее
3. Не рефакторить несвязанный код, только минимальное исправление
4. После исправления выводить список изменённых файлов""",
        options=ClaudeAgentOptions(
            allowed_tools=["Read", "Edit", "Bash", "Glob", "Grep"],
            permission_mode="acceptEdits",
            hooks=audit_hooks,
            max_turns=30,
        ),
    ):
        if hasattr(message, "result"):
            result_text = message.result
    return result_text
```

### Пятый этап: Testing + Report Generation

```python
async def run_test_and_report(fix_result: str) -> str:
    """Запустить тесты, генерировать финальный отчёт"""
    result_text = ""
    async for message in query(
        prompt=f"""Выполнить следующие операции:
1. Запустить полный набор тестов (npm test или pytest)
2. Статистика процента прохождения тестов
3. Генерировать Markdown формат отчёт качества в pr-report.md, включить:
   - Количество найденных проблем code review и распределение severity
   - Количество security уязвимостей
   - Содержание автоматического исправления: {fix_result}
   - Процент прохождения тестов
   - Финальный вывод: рекомендуется ли merge""",
        options=ClaudeAgentOptions(
            allowed_tools=["Read", "Bash", "Write", "Glob"],
            hooks=audit_hooks,
            max_turns=15,
        ),
    ):
        if hasattr(message, "result"):
            result_text = message.result
    return result_text
```

### Шестой этап: цепь вся pipeline

```python
import subprocess

async def run_pipeline():
    """Полная PR quality guard pipeline"""
    print("🔍 Фаза 1/4: Code Review...")
    pr_diff = subprocess.run(
        ["git", "diff", "main...HEAD"], capture_output=True, text=True
    ).stdout
    review_result = await run_code_review(pr_diff)

    print("🛡️ Фаза 2/4: Security Scan...")
    security_result = await run_security_scan()

    print("🔧 Фаза 3/4: Auto Fix...")
    fix_result = await run_auto_fix(review_result, security_result)

    print("✅ Фаза 4/4: Test Verify + Report Generation...")
    report = await run_test_and_report(fix_result)

    # Сохранить лог аудита
    with open("audit-log.json", "w") as f:
        json.dump(audit_log, f, indent=2, ensure_ascii=False)

    print(f"Pipeline завершена, лог аудита сохранён (всего {len(audit_log)} операций записано)")
    return report

asyncio.run(run_pipeline())
```

### Энтерпрайз level дизайна размышления

Эта pipeline воплощает несколько ключевых принципов enterprise дизайна:

**Минимум権限**: agent code review и security scan имеют только read권限, невозможно случайно менять код. Только agent автоматического исправления имеет권限 писать, и ограничен `acceptEdits` режимом.

**Аудитируемо**: каждый шаг операции каждого agent через Hook записано в лог аудита. Если что-то неправильно произошло, можно отследить какой agent когда что делал.

**Результаты в цепь**: вывод предыдущего agent это ввод следующего. Результаты code review идут в auto fix, результаты auto fix идут в test verify. Каждый этап имеет чёткий контракт ввод вывода.

**Стоимость контролируется**: каждый agent установлен `max_turns` ограничение, предотвращает какой-то этап из-под контроля. Production окружении можно добавить `max_budget_usd` для бюджет контроля.

**Расширяемо**: хотите добавить новый этап? Например добавить "documentation check agent" или "performance benchmark agent", просто напишите новую функцию, вставьте в pipeline. Готово.

Этот паттерн прямо может встроиться в GitHub Actions или GitLab CI, каждый PR автоматически запустит, действительно достичь "AI-driven code quality guard".

---

## Обработка ошибок

Agent SDK предоставляет чистые типы исключений, удобны для production окружении容错:

```python
from claude_agent_sdk import query, CLINotFoundError, ProcessError

try:
    async for msg in query(prompt="анализировать код"):
        print(msg)
except CLINotFoundError:
    print("Claude Code CLI не установлена, пожалуйста установите сначала")
except ProcessError as e:
    print(f"Процесс异常 выход, exit code: {e.exit_code}")
```

---

## Итоги

Claude Agent SDK основная ценность это升级 "model reasoning" на "controlled execution". Это не только генерирует текст, а может действительно завершить задачи в система инструментов с аудитом, с ограничениями.

Помните фраза из официального Anthropic блога: Agent SDK философия дизайна это "дать agent компьютер, позволить ему работать как человек".

Хороший agent приложение = чистый дизайн инструментов + чёткое граница задач + appropriate人工 мониторинг. Инструменты дают agent способность, граница дают ограничение, мониторинг даёт вам уверенность. Все три необходимы.

---

## Справочные материалы

### Официальные ресурсы

- [Официальная документация Agent SDK](https://platform.claude.com/docs/en/agent-sdk/overview) - самый авторитетный справочник
- [GitHub - claude-agent-sdk-python](https://github.com/anthropics/claude-code-sdk-python) - Python SDK исходный код
- [GitHub - claude-agent-sdk-typescript](https://github.com/anthropics/claude-agent-sdk-typescript) - TypeScript SDK исходный код
- [Примеры Agent проектов](https://github.com/anthropics/claude-agent-sdk-demos) - помощник email, research agent и т.д.

### Блог и учебник

- [Building agents with the Claude Agent SDK](https://claude.com/blog/building-agents-with-the-claude-agent-sdk) - Anthropic официальный инженерный блог, объясняет философию дизайна и архитектуру
- [Claude Agent SDK Python 学习 гайд](https://redreamality.com/blog/claude-agent-sdk-python-) - китайский дружелюбный, полный учебник с нуля
- [Claude Agent SDK полный учебник](https://blog.wenhaofree.com/en/posts/articles/claude-agent-sdk-tutorial/) - система инструментов, Agent Loop, controlled execution практика
- [12 практичных сценариев Agent SDK](https://skywork.ai/blog/claude-agent-sdk-use-cases-2025/) - покрывает кодирование, данные, автоматизация и т.д.
- [Step-by-Step Agent учебник](https://skywork.ai/blog/how-to-use-claude-agent-sdk-step-by-step-ai-agent-tutorial/) - TypeScript + Python двусторонний учебник

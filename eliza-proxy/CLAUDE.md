# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# eliza-proxy

HTTP proxy к Yandex Eliza API с OAuth, роутингом по провайдерам, нормализацией SSE, отслеживанием usage/cost.

## Запуск

```bash
cp .env.example .env   # добавить ELIZA_TOKEN
npm install
npm start              # PORT=3100 (production)
npm run dev            # node --watch (development)
```

## Команды разработки

```bash
npm start              # Production
npm run dev            # Hot reload на изменение server.js
npm test               # Все 77 тестов
npm test -- lib/eliza-client/test/models.test.js  # Одна suite
```

Тесты используют `node:test` (встроенный test runner, Node 18+).

## Переменные окружения

| Переменная | Описание | По умолчанию |
|---|---|---|
| `ELIZA_TOKEN` | OAuth токен Yandex Eliza — обязателен | — |
| `PORT` | Порт сервиса | `3100` |
| `LOG_USAGE` | Писать usage в JSONL | `true` |
| `USAGE_LOG_FILE` | Путь к лог-файлу usage | `./usage.jsonl` |

**Получение токена:**
`https://oauth.yandex-team.ru/authorize?response_type=token&client_id=60c90ec3a2b846bcbf525b0b46baac80`

**Доступность моделей:**
- Работают: `deepseek-v3-1-terminus`, `deepseek-v3-2`, `glm-4-7` (internal/communal models)
- Требуют sec-review: Claude, Google, внешние DeepSeek, OpenAI
- Подробнее см. `docs/eliza-api-models-guide.md`

## API

| Method | Path | Описание |
|---|---|---|
| `GET` | `/v1/health` | Healthcheck + `modelsValidated` флаг |
| `GET` | `/v1/models` | Список моделей с prices и валидацией |
| `POST` | `/v1/chat` | SSE стриминг с usage tracking |
| `POST` | `/v1/probe` | Проверка доступности модели (sync) |
| `GET` | `/v1/usage` | Агрегированная статистика (in-memory) |

### `/v1/chat` SSE формат

Каждое событие — JSON на отдельной строке (CRLF):
```
data: {"text":"Hello"}
data: {"usage":{"input":10,"output":5,"cost_usd":0.0015}}
data: [DONE]
```

Клиенты зависят от этого формата. **Не менять без согласования.**

## Архитектура

### Модели и кеширование

- `getModels()` вызывает API один раз, результат кешируется
- Параллельные вызовы шарят единую fetch операцию
- После получения raw моделей запускается асинхронный `probe()` для валидации доступности
- `probe()` тестирует каждую модель параллельно, результаты кешируются на 30 сек

### lib/eliza-client/ модули

| Модуль | Роль |
|--------|------|
| `index.js` | Оркестрация: клиент, кеширование, обработка ошибок, retry logic |
| `models.js` | Парсинг API response, фильтрация non-chat моделей, нормализация мета |
| `routing.js` | Выбор endpoint по модели, reasoning tokens detection, provider inference |
| `streaming.js` | Асинхронный generator поверх ReadableStream, нормализация SSE (Anthropic/OpenAI) |
| `probe.js` | Параллельное тестирование доступности моделей с кешем |
| `test/` | Comprehensive тесты каждого модуля |

### Ключевые паттерны

**Кеширование с инвалидацией:**
- Raw models кешируются на срок жизни процесса
- Валидированные результаты обновляются асинхронно (probe)
- При разрыве соединения fallback на raw models

**Потоковая обработка:**
- `/v1/chat` возвращает ReadableStream, нормализованный в async generator
- Каждое событие: `{ delta?, usage?, done?, error? }`
- Обработка разрыва соединения на клиенте (res.on('close'))

**Routing:**
- `elizaConfig()` выбирает Eliza endpoint по модели (Anthropic/OpenAI/etc)
- `usesReasoningTokens()` — отдельные счетчики для reasoning vs output tokens (GPT-o1-style)
- Автоматическое определение provider из id модели

**Обработка ошибок:**
- `ElizaError` для HTTP ошибок (429 rate limit, 501 no streaming)
- Сетевые ошибки (ECONNRESET, ETIMEDOUT) retriable с backoff
- Graceful shutdown потока при разрыве соединения клиента

## Важно

- **Синхронизация:** `lib/eliza-client/` — источник истины в `groovy_agent/lib/eliza-client/`. При изменениях синхронизировать вручную.
- **SSE формат:** Клиенты (groovy_agent, др.) зависят от точного формата. Изменения требуют согласования.
- **Usage логирование:** JSONL файл, одна строка per request. Используется для аналитики costs.

# eliza-proxy

Standalone HTTP proxy к Yandex Eliza API. Добавляет OAuth auth, роутинг по провайдерам, нормализацию SSE, usage/cost tracking.

## Запуск

```bash
cp .env.example .env   # добавить ELIZA_TOKEN
npm install
npm start              # PORT=3100
```

## Переменные окружения

| Переменная | Описание | По умолчанию |
|---|---|---|
| `ELIZA_TOKEN` | OAuth токен — обязателен | — |
| `PORT` | Порт сервиса | `3100` |
| `LOG_USAGE` | Писать usage в файл | `true` |
| `USAGE_LOG_FILE` | Путь к лог-файлу | `./usage.jsonl` |

**Получение токена:**
`https://oauth.yandex-team.ru/authorize?response_type=token&client_id=60c90ec3a2b846bcbf525b0b46baac80`

## API

| Method | Path | Описание |
|---|---|---|
| `GET` | `/v1/health` | Healthcheck + статус валидации моделей |
| `GET` | `/v1/models` | Список моделей с prices |
| `POST` | `/v1/chat` | SSE стриминг |
| `POST` | `/v1/probe` | Проверка доступности модели |
| `GET` | `/v1/usage` | Агрегированная статистика |

## Тесты

```bash
node --test lib/eliza-client/test   # 77 тестов
```

## Ключевые файлы

- `server.js` — Express, все endpoints
- `lib/eliza-client/` — логика работы с Eliza (скопировано из groovy_agent)

## Важно

- `lib/eliza-client/` — источник истины в `groovy_agent/lib/eliza-client/`. При изменениях синхронизировать вручную.
- SSE формат `/v1/chat` — клиенты зависят от формата. Не менять без согласования.

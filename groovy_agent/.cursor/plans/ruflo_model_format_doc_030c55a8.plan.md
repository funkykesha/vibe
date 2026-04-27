---
name: ruflo model format doc
overview: Собрать и оформить документ по формату указания моделей для интеграции с Ruflo на основе данных Context7.
todos:
  - id: collect-sources
    content: Собрать подтверждённые правила формата моделей из Context7-источников Ruflo
    status: pending
  - id: write-md-doc
    content: Сформировать markdown-документ с JSON/YAML примерами и правилами naming/provider/env
    status: pending
  - id: final-check
    content: "Проверить полноту документа: обязательные поля, провайдеры, роутинг и env checklist"
    status: pending
isProject: false
---

# Документ по формату моделей для Ruflo

## Что уже выяснено через Context7
- Основная точка конфигурации моделей: `config/config.json` (массив `models`).
- Поля модели в JSON: `name`, `displayName`, `description`, `provider`, `supportsTools`, `multimodal`, `parameters`.
- Поддерживаемые провайдеры: `gemini`, `openai`, `openrouter`.
- Конвенции имён для роутинга:
  - `gemini-*` → Google
  - `gpt-*` → OpenAI
  - прочие/вендорные префиксы → OpenRouter
- Обязательные env-переменные зависят от провайдера: `OPENAI_API_KEY`, `GOOGLE_API_KEY`, и др.
- Для LiteLLM YAML используется `model_list[].litellm_params.model` в формате `provider/model` (например, `openai/gpt-4o-mini`).

## Что будет в итоговом документе
- Краткий раздел “Как указывать модель в Ruflo”.
- Таблица/список допустимых `provider` и примеров `name`.
- Минимальный валидный JSON-пример для `config/config.json`.
- Пример LiteLLM YAML-конфига с provider-префиксами.
- Раздел “Проверка перед запуском” (чеклист env и соответствия `name`/`provider`).
- Ссылки на источники:
  - [Ruflo repository](https://github.com/ruvnet/ruflo)
  - [MODELS.md](https://github.com/ruvnet/ruflo/blob/main/docs/MODELS.md)
  - [DOCKER.md](https://github.com/ruvnet/ruflo/blob/main/docs/DOCKER.md)

## Формат артефакта
- Подготовить markdown-документ в проекте: [`/Users/agaibadulin/Desktop/projects/vibe/groovy_agent/docs/ruflo-model-format.md`](/Users/agaibadulin/Desktop/projects/vibe/groovy_agent/docs/ruflo-model-format.md).
- Язык документа: русский, с точными именами полей/переменных в оригинальном виде.
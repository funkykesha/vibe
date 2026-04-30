## Why

При запуске сервера все модели остаются в статусе ⏳ и никогда не переходят в ✅/❌. Проблема в race condition: `onModelProbed` callback проверяет `if (!rawModels) return`, но `rawModels` и `modelsByProvider` устанавливаются асинхронно — probe может завершиться раньше, чем данные о моделях инициализированы.

## What Changes

- Устранить race condition между инициализацией `rawModels`/`modelsByProvider` и callback `onModelProbed`
- Гарантировать что данные провайдеров готовы до того как начнётся probe
- Очистить фрагментарные изменения в `server.js` (частичные fix из предыдущей сессии)

## Capabilities

### New Capabilities

- (нет новых capabilities)

### Modified Capabilities

- (нет изменений в spec-level behavior)

## Impact

- `server.js` — race condition fix в логике `onModelProbed` и `app.listen`
- `lib/eliza-client/index.js` — возможно, изменение порядка вызовов probe
- Тесты не затрагиваются

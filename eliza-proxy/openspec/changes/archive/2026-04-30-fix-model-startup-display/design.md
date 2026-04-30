## Context

При запуске сервера `eliza-proxy` выводится таблица моделей с прогресс-барами и статусами. Probe моделей запускается асинхронно в фоне через `startProbeIfNeeded()` внутри `eliza-client`. Callback `onModelProbed` в `server.js` обновляет вывод когда probe завершается.

Текущее состояние `server.js` содержит фрагментарные изменения из предыдущей сессии: две разные переменные (`rawModels`, `modelsByProvider`), частично refactored `onModelProbed` и `app.listen`.

Корень проблемы: `onModelProbed` проверяет `modelsByProvider[provider]` но эта мапа заполняется в `app.listen()` — async функции. Если probe быстрее завершается чем `app.listen()` обрабатывает ответ API, callback получает пустую мапу и отдаёт `return`.

## Goals / Non-Goals

**Goals:**
- Устранить race condition: гарантировать что `modelsByProvider` заполнена до первого вызова `onModelProbed`
- Привести `server.js` в чистое состояние (убрать `rawModels`, только `modelsByProvider`)
- Вывод финальных статусов (✅/❌) работает стабильно

**Non-Goals:**
- Изменение формата вывода в терминале
- Рефакторинг `eliza-client` внутри
- Добавление real-time обновлений (перезапись строк)

## Decisions

**Решение: передать `modelsByProvider` в `createElizaClient` как параметр**

Нет — усложняет интерфейс клиента, который не должен знать про display-логику.

**Решение: использовать `onValidated` callback вместо `onModelProbed`**

Нет — `onValidated` вызывается одним блоком после завершения всех probe, нет поэтапного вывода.

**Выбрано: дождаться getModels() перед probe**

`getModels()` в eliza-client возвращает сразу после получения raw моделей и запускает probe в фоне. В `app.listen()` нужно:
1. Вызвать `getModels()` — получить raw models
2. Синхронно заполнить `modelsByProvider` из полученных моделей
3. Только после этого probe начнёт звать `onModelProbed`

Проблема: probe запускается внутри `getModels()` асинхронно. Если он завершится мгновенно (кеш), то `onModelProbed` будет вызван до возврата из `getModels()`.

**Выбрано финально: заполнять `modelsByProvider` до вызова `getModels()`**

Нет — при первом запуске моделей нет.

**Выбрано финально: ждать getModels(), заполнить модели, потом запустить probe явно**

Изменить порядок: сначала получить raw models, заполнить `modelsByProvider`, потом запустить probe. Для этого передать `_skipProbe: true` и вызвать probe вручную через `onValidated` callback. Нет — слишком сложно.

**Выбрано: хранить probe events в очереди до готовности**

В `onModelProbed` callback: если `modelsByProvider` ещё не заполнена — складывать события в очередь. Когда `modelsByProvider` заполняется, сразу обработать очередь. Просто и без изменений в eliza-client.

## Risks / Trade-offs

- [Race] Probe может завершиться быстрее (кеш) → очередь покроет этот случай
- [Overhead] Очередь занимает память → пренебрежимо мало (< 100 объектов)
- [Ordering] Порядок событий в очереди = порядок probe → детерминирован при обработке из очереди

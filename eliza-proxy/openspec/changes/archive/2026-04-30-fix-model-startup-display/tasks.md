## 1. Очистка server.js

- [x] 1.1 Убрать переменную `rawModels` (строка 21) — заменить на `modelsByProvider`
- [x] 1.2 Убрать undefined `modelCountByProvider` из `app.listen()` (строки 188-192) — она не объявлена нигде
- [x] 1.3 В `app.listen()` после `getModels()` правильно заполнить `modelsByProvider` через `groupByProvider(models)` (функция уже импортирована)

## 2. Race condition fix

- [x] 2.1 Добавить флаг `let modelsByProviderReady = false` и массив `let pendingProbeEvents = []`
- [x] 2.2 В `onModelProbed`: если `!modelsByProviderReady` — пушить `{ provider, model }` в `pendingProbeEvents` и return
- [x] 2.3 После заполнения `modelsByProvider` в `app.listen()`: поставить `modelsByProviderReady = true` и прогнать `pendingProbeEvents` через ту же логику `onModelProbed`
- [x] 2.4 Очистить `pendingProbeEvents` после обработки

## 3. Проверка

- [x] 3.1 Запустить `npm start`, убедиться что все группы выводятся с ✅/❌ статусами
- [x] 3.2 Проверить что нет упоминаний `rawModels` или `modelCountByProvider` в server.js

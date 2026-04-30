## 1. Modify probe.js

- [x] 1.1 Убрать импорт/использование `mapWithConcurrency` из probe.js (строки 185-196)
- [x] 1.2 В `runProbe()` заменить `mapWithConcurrency` на `for...of` loop с последовательной проверкой моделей
- [x] 1.3 Каждая модель проверяется через `probeModel()` с try-catch для обработки ошибок
- [x] 1.4 После каждой модели вызвать `onModelProbed(provider, model)` если callback существует

## 2. Update server.js probe initialization

- [x] 2.1 Убедиться что callback `onModelProbed` правильно регистрируется в `createElizaClient`
- [x] 2.2 `processProbeEvent` правильно обновляет probe статус в `modelsByProvider[provider]`

## 3. Verification

- [x] 3.1 Запустить `npm start` и убедиться что начальный вывод появляется с ⏳
- [x] 3.2 Наблюдать что каждые 3-5 секунд статусы обновляются (модели переходят из ⏳ в ✅/❌)
- [x] 3.3 После завершения всех моделей все группы показывают финальные статусы

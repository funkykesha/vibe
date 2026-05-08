## Why

Текущая модель с polling в menu-agent создает задержки, лишнюю нагрузку и не гарантирует моментальное обновление UI при изменениях состояния сервисов. Нужен событийный канал daemon -> clients, чтобы доставлять state changes сразу после возникновения.

Текущее поведение:
- `CLI/Menu -> Socket -> Daemon` (команды, фактически однонаправленно)
- `Daemon -> File -> Menu/CLI` (состояние через polling, ~3 сек)
- Задержка доставки состояния: до 3 секунд
- Лишние операции: периодическое чтение state-файла каждые 3 секунды

Целевое поведение:
- `CLI/Menu <-> Socket <-> Daemon` (двунаправленный канал)
- Задержка доставки состояния: порядка ~1ms в локальном процессе/хосте
- Лишние операции polling: 0 (event-driven push вместо таймера)

## What Changes

- Ввести двунаправленный IPC-канал между daemon и клиентами (menu-agent/CLI) на Unix Socket.
- Разрешить стратегический вариант: XPC вместо Unix Socket, если принято решение оставаться строго в macOS-only модели.
- Добавить push-модель доставки изменений состояния от daemon ко всем подключенным клиентам.
- Удалить polling-таймер из menu-agent и перевести обновление UI на события IPC.
- Сохранить корректное поведение при переподключении клиента и при временной недоступности daemon.

## Capabilities

### New Capabilities
- `bidirectional-ipc-state-stream`: двунаправленный IPC канал с подпиской клиентов и push-рассылкой state changes от daemon.

### Modified Capabilities
- `ipc-unix-socket`: расширение протокола до постоянных подключений/обратных сообщений и событийной доставки state updates.
- `adaptive-menu-polling`: изменение модели обновления menu-agent с polling на event-driven push.

## Impact

- Affected code:
  - `Sources/StartWatch/IPC/IPCServer.swift`
  - `Sources/StartWatch/IPC/IPCClient.swift`
  - `Sources/StartWatch/MenuAgent/MenuAgentDelegate.swift`
  - `Sources/StartWatch/Daemon/MenuBarController.swift` (интеграция с новым источником состояния)
  - потенциально `Sources/StartWatch/IPC/IPCMessage.swift` (расширение message model)
- Affected behavior:
  - более быстрые и предсказуемые обновления UI
  - уменьшение фоновой активности из-за отказа от polling
  - новые требования к reconnect/backpressure/error-handling в IPC
- Risks:
  - сложность lifecycle постоянных подключений
  - необходимость четко выбрать транспорт (Unix Socket vs XPC) до design-фазы
  - возможные edge cases при запуске/перезапуске daemon и подписчиков

## Why

Постоянная запись состояния на каждое изменение создает лишний I/O и может увеличивать задержки на горячем пути обновлений. Перенос рабочего состояния в память с периодическим flush позволит снизить нагрузку на диск и сохранить приемлемую устойчивость при падениях.

Сейчас:
- Каждый check-цикл (~30 сек): `JSON encode -> запись на диск`
- Каждый poll (~3 сек): `чтение с диска -> JSON decode`
- Итого: порядка `~20` файловых операций в минуту (для 10 сервисов)

Это дает лишний постоянный disk I/O и задержки распространения актуального состояния.

Цель:
- `RAM` — source of truth для runtime state
- `Диск` — только backup/snapshot для persistence между перезагрузками

## What Changes

- Ввести in-memory слой текущего состояния daemon как основной runtime source of truth.
- Добавить периодический flush in-memory состояния на диск (snapshot/checkpoint) вместо записи на каждое событие.
- Определить политику flush: интервал, принудительный flush на shutdown, flush при критических переходах.
- Обеспечить восстановление состояния после рестарта из последнего корректного snapshot.
- Явно зафиксировать зависимость от III: архитектуры событийного IPC из `bidirectional-unix-socket`.
- Убрать runtime-модель "каждый poll читает диск" и заменить ее на in-memory reads с backup persistence.

## Capabilities

### New Capabilities
- `in-memory-state-checkpointing`: runtime состояние в памяти с периодическим сохранением на диск и восстановлением после перезапуска.

### Modified Capabilities
- `startup-state-propagation`: обновление источника стартового состояния и механизма публикации после восстановления snapshot.
- `ipc-unix-socket`: синхронизация push/state-stream поведения с in-memory source of truth (зависимость от III).

## Impact

- Affected code:
  - `Sources/StartWatch/Core/StateManager.swift`
  - `Sources/StartWatch/Daemon/AppDelegate.swift` (или эквивалент coordinator state flow)
  - IPC state publishing path (`IPCServer`/state broadcast integration)
- Affected behavior:
  - runtime state reads/writes переносятся в RAM
  - disk используется только для checkpoint/restore
  - значительно меньше частота файловых операций в steady-state
  - возможна потеря последних изменений в пределах flush-окна при аварийном завершении
  - более быстрый hot path обновлений состояния
- Dependencies:
  - зависит от III (`bidirectional-unix-socket`) для полного эффекта event-driven публикации состояния
- Risks:
  - выбор слишком большого flush-interval увеличит окно потери данных
  - нужен четкий shutdown flush и crash-consistency формат snapshot

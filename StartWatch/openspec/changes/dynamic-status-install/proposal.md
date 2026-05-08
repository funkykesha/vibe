## Why

`startwatch install` может выполняться заметно долго на шагах `launchctl`, но в терминале почти нет живого фидбека. Пользователь видит "тишину" и воспринимает это как зависание.

## What Changes

- Добавить интерактивный, пошаговый вывод в `startwatch install` с явным описанием текущей операции.
- Показать пользователю, какие системные действия выполняются (`bootout`, `bootstrap`, `kickstart`, cleanup legacy).
- Добавить промежуточные статусы и итог каждого шага (ok/warn/fail), чтобы было понятно, жив ли процесс.
- Уточнить подсказки при долгих шагах (например, что `launchctl` может занять несколько секунд).

## Capabilities

### New Capabilities
- `dynamic-install-status`: интерактивный прогресс и понятные подсказки в CLI-потоке выполнения `startwatch install`.

### Modified Capabilities
- `headless-daemon-mode`: уточнение требований к UX/наблюдаемости при управлении lifecycle daemon через CLI.

## Impact

- Affected code:
  - `Sources/StartWatch/CLI/Commands/InstallCommand.swift`
  - при необходимости: общие CLI-format helpers для единообразного step-вывода
- Affected behavior:
  - пользователь видит текущий шаг и причину задержки вместо "молчания"
  - выше предсказуемость install flow и меньше ложных прерываний `Ctrl+C`
- Tests:
  - добавить/обновить тесты на присутствие прогресс-вывода и ключевых сообщений шагов.

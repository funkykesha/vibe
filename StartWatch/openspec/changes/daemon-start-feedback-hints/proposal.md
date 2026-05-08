## Why

При запуске daemon из menu-agent пользователь не видит явного фидбека: состояние остается "Daemon not running", и выглядит как зависание. Нужна графическая подсказка, что запуск уже выполняется.

## What Changes

- Добавить в menu-agent промежуточное визуальное состояние "daemon starting" после клика `Start Daemon`.
- Показать пользователю явный индикатор прогресса (статус/спиннер/disabled action), пока идет `launchctl kickstart/bootstrap`.
- Обновить переходы состояний: offline -> starting -> online или offline + ошибка.
- Добавить текстовые подсказки в терминальном выводе для CLI-операций запуска daemon, чтобы было понятно на каком шаге задержка.

## Capabilities

### New Capabilities
- `daemon-start-feedback`: UX и state-machine для визуальной индикации запуска daemon из menu-agent и явного результата операции.

### Modified Capabilities
- `menu-bar-four-states`: расширение поведения menu bar для промежуточного состояния запуска daemon и корректных переходов.
- `headless-daemon-mode`: уточнение UX/операционного фидбека для запуска daemon через launchctl из клиентского UI/CLI.

## Impact

- Affected code:
  - `Sources/StartWatch/Daemon/MenuBarController.swift`
  - `Sources/StartWatch/MenuAgent/MenuAgentDelegate.swift`
  - `Sources/StartWatch/CLI/Commands/InstallCommand.swift` (уже частично содержит прогресс-лог; возможно синхронизировать формат)
- Affected behavior:
  - UX меню в оффлайн-состоянии daemon
  - Наблюдаемость прогресса и ошибок при старте daemon
- Tests:
  - Потребуются проверки переходов состояния UI и fallback-веток запуска.

# Active Context

## Current State
v2.0 menu bar app полностью реализован и работает.
Иконка в menu bar отображается. Daemon + menu-agent работают как два процесса.

## Last Session Work
- Реализованы все 10 шагов плана (menu bar app refactor)
- Создан `Resources/StartWatchMenu-Info.plist` (LSUIElement=YES)
- `install.sh` собирает `~/Applications/StartWatchMenu.app` bundle
- Добавлен `ProcessManager` (старт/стоп/рестарт сервисов без терминала)
- IPC расширен: `start_service`, `stop_service`, `restart_service`
- `DaemonCoordinator` подключён к `ProcessManager` через IPC callbacks
- `ConfigEditorWindow` — NSPanel с NSTextView для редактирования JSON конфига
- `MenuBarController` — подменю (Запустить/Остановить/Перезапустить) на каждый сервис
- `MenuAgentDelegate` — подключён config editor и кнопки сервисов
- Исправлен краш `NotificationManager` в daemon mode (guard on bundleIdentifier)
- Исправлен баг: `.app` bundle запускается через `open -na` (не прямой Process())

## Why Icon Wasn't Showing — Root Causes
1. Бинарник без `.app` bundle → macOS не регистрирует NSStatusItem
2. Старый binary в `StartWatchMenu.app/Contents/MacOS/` после `sudo cp` к `/usr/local/bin`
3. `NotificationManager.shared` вызывался без bundleIdentifier → краш daemon

## Pending (v2.1 backlog)
- Исправить `representedObject = ("start", name)` в MenuBarController — Swift tuple не bridging через ObjC id, заменить на struct
- Unix socket IPC (вместо file-based)
- Swift 6 concurrency fix в ServiceChecker
- Настройки окно (SwiftUI)

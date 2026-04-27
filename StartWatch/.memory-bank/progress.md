# Progress

## Done
- [x] Phase 0–7: все исходные файлы, тесты, install script (v1.0)
- [x] Build fixes, runtime fixes, установка на машину (v1.0)
- [x] **v2.0: Menu bar app refactor**
  - [x] `Resources/StartWatchMenu-Info.plist`
  - [x] `install.sh` — `.app` bundle сборка
  - [x] `Core/ProcessManager.swift` — старт/стоп/рестарт без терминала
  - [x] IPC расширен (`start_service`, `stop_service`, `restart_service`)
  - [x] `DaemonCoordinator` подключён к ProcessManager
  - [x] `MenuAgent/ConfigEditorWindow.swift` — NSPanel JSON editor
  - [x] `MenuBarController` — подменю per-service
  - [x] `MenuAgentDelegate` — editor + service buttons
  - [x] `NotificationManager` crash fix (bundleIdentifier guard)
  - [x] Иконка в menu bar работает

## In Progress
- [ ] Проверить кнопки Запустить/Остановить/Перезапустить через UI

## Backlog (v2.1)
- [ ] Fix `representedObject` tuple bridging в MenuBarController (заменить на struct)
- [ ] Unix socket IPC (вместо file-based polling)
- [ ] Swift 6 concurrency fix в ServiceChecker
- [ ] Settings window (SwiftUI)
- [ ] README.md (onboarding)

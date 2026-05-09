# Progress

## Done
- [x] Architecture diagrams refreshed (2026-05-09)
  - [x] `docs/architecture.md` now documents the current app-bundle LaunchAgent deployment, bind-first socket ownership, owner/client menu modes, Unix socket subscriptions, and checkpoint fallback
  - [x] memory-bank architecture/tech notes updated to remove stale file-polling-as-primary IPC model
- [x] Runtime-path cleanup for app launch/check confusion (2026-05-08)
  - [x] `IPCClient.isConnected()` uses Unix socket connectivity instead of `pgrep`
  - [x] `startwatch check` no longer has the 3s daemon-trigger pause before live output
  - [x] app-bundle daemon readiness kickstarts loaded-but-stopped LaunchAgent
  - [x] installer removes legacy `com.startwatch.daemon` and installs canonical `com.user.startwatch`
  - [x] `startwatch stop` handles both canonical and legacy LaunchAgent labels
  - [x] verification: `swift test` 69/69, release build, OpenSpec strict validation
- [x] Menu-agent visibility follow-up (2026-05-08)
  - [x] status item now uses text `SW/SW?/SW!/SW...` instead of custom emoji image
  - [x] installer stops stale `menu-agent` before replacing app bundle binary
  - [x] menu-agent `Start Daemon` uses canonical `com.user.startwatch`
  - [x] verification: `swift test` 87/87, `zsh -n install.sh`, `git diff --check`
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
- [x] LaunchAgent menu regression fix
  - [x] Installed plist repaired to run app bundle binary with `daemon`, without `--no-menu`
  - [x] `install.sh` now generates plist from resolved `MENU_BIN`
  - [x] `DoctorCommand` now checks LaunchAgent args and rejects `--no-menu`

## In Progress
- [ ] OpenSpec change: `daemon-supervision-hardening`
  - [x] proposal
  - [x] design
  - [x] specs
  - [x] tasks
- [ ] Проверить кнопки Запустить/Остановить/Перезапустить через UI
- [ ] Пользователь должен вручную запустить `./install.sh` для применения нового bundle + LaunchAgent migration на `/Applications`
- [ ] После install проверить `launchctl print gui/$(id -u)/com.user.startwatch` и double-click `/Applications/StartWatchMenu.app`

## Backlog (v2.1)
- [ ] Fix `representedObject` tuple bridging в MenuBarController (заменить на struct)
- [ ] Unix socket IPC (вместо file-based polling)
- [ ] Swift 6 concurrency fix в ServiceChecker
- [ ] Settings window (SwiftUI)
- [ ] README.md (onboarding)

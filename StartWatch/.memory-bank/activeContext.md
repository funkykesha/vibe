# Active Context

## Current State
v2.0 menu bar app реализован, но installed runtime может быть в переходном состоянии после смены LaunchAgent модели.
Диагностика 2026-05-08: на машине был загружен legacy `com.startwatch.daemon`, canonical `com.user.startwatch` отсутствовал, daemon был `not running`, socket/cache могли оставаться stale.

## Current OpenSpec Work
- `daemon-supervision-hardening` change scaffolded with default `spec-driven` schema.
- Proposal, design, specs, and tasks artifacts are complete.
- Strict validation passes for `daemon-supervision-hardening`.
- Key design decisions: classify `unresponsive` via IPC timeout or live PID without socket; force quit is graceful-first; PID is rechecked before each signal; recovery means post-restart `getStatus` response; menu force-stop action is latched while running.

## Last Session Work
- Updated `docs/architecture.md` C4 diagrams to match the current app-bundle LaunchAgent, bind-first socket ownership, Unix socket subscriptions, checkpoint fallback, and deployment paths.
- Updated memory-bank architecture/tech notes so future work treats `last_check.json` as checkpoint fallback and `~/.local/state/startwatch/sock` as the primary IPC channel.
- Исправлен runtime-path confusion: `IPCClient.isConnected()` теперь проверяет Unix socket connect, а не `pgrep -f "startwatch daemon"`.
- `startwatch check` больше не ждёт 3 секунды и не печатает ложное `Check triggered via daemon`; daemon trigger теперь явный `Daemon check requested`, затем идёт foreground-check.
- `DaemonCommand.ensureDaemonRunning()` теперь отличает `state = running` от `state = not running` и kickstart-ит loaded-but-stopped LaunchAgent.
- `install.sh` мигрирует legacy `com.startwatch.daemon.*`, ставит canonical `com.user.startwatch.plist`, обновляет daemon log paths в `.local/state/startwatch`, bootstrap + kickstart.
- `startwatch stop` bootout-ит и canonical `com.user.startwatch`, и legacy `com.startwatch.daemon`.
- После пользовательской проверки `menu-agent` был жив, но UI был невидим/неочевиден: `MenuBarController` переведён с кастомной emoji `NSImage` на текстовый status item `SW/SW?/SW!/SW...`.
- `install.sh` теперь убивает stale `menu-agent` перед заменой bundle binary, чтобы старый UI-процесс не оставался с прежним кодом.
- `MenuAgentDelegate.startDaemonViaLaunchctl()` переведён на canonical label `com.user.startwatch`.
- Проверено: `swift test` 69/69, `swift build -c release`, `openspec validate fix-app-launch-arch --strict`.
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
4. Loaded-but-stopped LaunchAgent считался готовым, потому что код проверял только `launchctl print` exit status, не `state = running`
5. `startwatch check` доверял `pgrep`, поэтому мог сообщать daemon path даже при stale/broken IPC
6. Текущий `menu-agent` мог быть жив, но status item был невидим из-за кастомной emoji image; textual `SW` должен быть заметен в menu bar
7. Installer раньше не останавливал уже запущенный `menu-agent`, поэтому после копирования нового bundle UI мог продолжать работать на старом mapped binary

## Pending (v2.1 backlog)
- Исправить `representedObject = ("start", name)` в MenuBarController — Swift tuple не bridging через ObjC id, заменить на struct
- Unix socket IPC (вместо file-based)
- Swift 6 concurrency fix в ServiceChecker
- Настройки окно (SwiftUI)

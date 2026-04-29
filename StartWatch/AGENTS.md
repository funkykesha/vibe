# StartWatch — Agent Notes

## Menu Bar Icon

- macOS 26 требует `codesign --force --deep --sign -` для `.app` bundle, иначе UI-агент не запускается (`RBSRequestErrorDomain Code=5`)
- После смены `CFBundleIdentifier` обязательно `killall SystemUIServer` — иначе иконка не появится
- Если иконка не появляется, рабочий reset: `pkill -f startwatch` → новый `CFBundleIdentifier` в `StartWatchMenu.app/Contents/Info.plist` → `codesign --force --deep --sign -` → `killall SystemUIServer` → `open -na ... --args menu-agent`
- Запуск через `open -na App.app`, не прямой путь к бинарнику — macOS иначе не регистрирует UI-агент
- See `docs/macos-menubar-icon-guide.md` for full debug checklist and architecture.

## Deploy

- **Не запускай `install.sh` самостоятельно** — требует `sudo`, sandbox Claude блокирует. Пользователь запускает вручную через `! ./install.sh`
- **`swift build` требует `dangerouslyDisableSandbox: true`** — иначе sandbox блокирует компилятор
- Бинарник и `.app` живут в `/Applications/` (не `~/Applications/`) — исправлено в v1.1
- CLI wrapper в `/usr/local/bin/startwatch` должен использовать **двойные кавычки** при присваивании пути: `MENU_BIN="/path/..."` — одинарные не раскрывают переменные
- LaunchAgent должен запускать bundle-бинарник (`.../StartWatchMenu.app/Contents/MacOS/startwatch daemon`), иначе на macOS 26 возможен `AppleSystemPolicy: load code signature error 2`
- `install.sh` пишет build warnings в `/tmp/startwatch-build.log`

## IPC

- Daemon→Menu: `~/.config/startwatch/last_check.json` (polling)
- Menu→Daemon: `~/.config/startwatch/menu_command.json`

## Runtime Architecture

- `startwatch daemon` запускает headless-daemon и отдельно поднимает menu-agent как `.app` (через `open`)
- Menu UI и уведомления должны жить в bundle-процессе (`StartWatchMenu.app`), не в daemon/CLI процессе
- CLI-команды (`doctor/status/check/...`) должны роутиться в `CLIRouter` даже при запуске из `.app`, иначе команда зависает в `NSApplication.run()`
- CLI `startwatch status` читает кэш последней проверки; для live-проверки использовать `startwatch check`

## LaunchAgent

- LaunchAgent plist: `com.user.startwatch.plist`
- После `install.sh` агент может стартовать только на следующий логин; для немедленного старта: `startwatch daemon &`
- Если после установки иконки нет, сначала проверить что запущены оба процесса: daemon + menu-agent

## Quick Debug

- Проверка самого приложения: `startwatch doctor`
- Логи сборки installer: `/tmp/startwatch-build.log`
- Полный runbook по проблемам иконки: `docs/macos-menubar-icon-guide.md`

## Terminal Integration

- **Warp авто-выполнение нереализуемо без явного разрешения пользователя.** URL scheme только вставляет в buffer (intentional security). AppleScript keystroke требует Accessibility permission — Warp это явно запрещает политикой. Фича закрыта как невозможная без ручных действий пользователя.
- Текущее поведение (финальное): при выборе Warp без Accessibility — показывается NSAlert с инструкцией + открывается `warp://action/new_tab` без команды. See `docs/warp-terminal-integration.md`.
- **`ProcessManager.stop(name:)`** убивает только процессы, запущенные самим StartWatch. Для внешних процессов используй `stop(service:)` — он делает `pkill -f` (process type) или `lsof -ti tcp | xargs kill -9` (port/http type).

## Daemon Logging & Testing

- **No daemon logging infrastructure** — `print()` statements don't appear in daemon output; stdout/stderr suppressed. File-based logging required for debugging. Tests don't cover hotreload behavior (manual verification only).
- **Priority:** Implement proper logging layer + integration tests for hotreload before next daemon-side feature work.

## Tests

- `swift test` — 19 тестов, все должны проходить перед коммитом

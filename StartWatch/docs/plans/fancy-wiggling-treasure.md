# Plan: Fix menu bar icon not appearing

## Context

Иконка StarWatch не появляется в menu bar. Причина установлена по документу `macos-menubar-guide.md` (Причина 3): запуск menu-agent через прямой `Process()` (путь к бинарнику) не регистрирует процесс как UI-агент в macOS. Нужен `open -na`.

Оригинальный код использовал `open -na`, но с `terminationHandler` — это вызывало respawn-петлю (150+ процессов). Фикс петли заменил `open -na` на прямой путь, сломав регистрацию UI.

## Корень проблемы

`AppDelegate.swift:spawnMenuAgentIfNeeded()` сейчас:
```swift
process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
process.arguments = ["-a", appPath, "--args", "menu-agent"]  // -a без -n
```

Нужно `-na`. Без `-n` macOS иногда не регистрирует новый инстанс как UI-агент.

## Изменения

### 1. `Sources/StartWatch/Daemon/AppDelegate.swift`

Заменить `-a` на `-na` в `spawnMenuAgentIfNeeded()`:

```swift
process.arguments = ["-na", appPath, "--args", "menu-agent"]
```

`isMenuAgentRunning()` уже защищает от respawn-петли — вызов `open -na` происходит только когда процесс не запущен. Timer на 30с обеспечивает восстановление после крэша.

### 2. `Sources/StartWatch/Daemon/MenuBarController.swift`

Убрать debug `print` строки, добавленные при диагностике (строки с `[MenuBar]`).

### 3. `Sources/StartWatch/main.swift`

Откатить усложнение парсинга аргументов — вернуть простой вариант как в гайде:

```swift
let args = Array(CommandLine.arguments.dropFirst())
let command = args.first ?? "status"
```

`open -na --args menu-agent` передаёт `menu-agent` как первый аргумент напрямую, без системных инъекций.

## Критические файлы

- `Sources/StartWatch/Daemon/AppDelegate.swift` — строка `process.arguments`
- `Sources/StartWatch/Daemon/MenuBarController.swift` — убрать debug print
- `Sources/StartWatch/main.swift` — упростить парсинг

## Верификация

```bash
# 1. Убить все процессы
pkill -f startwatch

# 2. Пересобрать и установить
cd /path/to/StarWatch && ./install.sh

# 3. Запустить daemon
startwatch daemon &

# 4. Проверить — один menu-agent, иконка видна
ps aux | grep startwatch | grep -v grep
# Ожидаемо: 1x daemon, 1x menu-agent
# Иконка StarWatch в menu bar
```



# StartWatch — Финальный план

## Концепция

Menu bar app + полноценный CLI-интерфейс. Menu bar — это "светофор" (видно статус), а вся работа — через CLI в любимом терминале пользователя.

```
┌─────────────────────────────┐
│  Menu Bar: ● / ◐            │
│  ├─ ✅ Redis                │
│  ├─ ❌ Backend API          │
│  ├─ ─────────               │
│  ├─ Open CLI    ⌘T          │  ──► открывает Warp/iTerm/Terminal с `startwatch status`
│  ├─ Check Now   ⌘R          │
│  ├─ Settings    ⌘,          │
│  └─ Quit        ⌘Q          │
└─────────────────────────────┘

$ startwatch status          # красивый отчёт
$ startwatch check           # запустить проверку сейчас
$ startwatch start backend   # запустить конкретный сервис
$ startwatch restart all     # перезапустить всё упавшее
$ startwatch config          # открыть конфиг в $EDITOR
$ startwatch log             # посмотреть лог проверок
$ startwatch doctor          # диагностика самого startwatch
```

---

## Архитектура

```
                    ┌──────────────────────────────┐
                    │        Menu Bar Agent         │
                    │   (фоновый NSApplication)     │
                    │                               │
                    │  • иконка статуса              │
                    │  • таймер проверок             │
                    │  • нотификации                 │
                    │  • кнопка "Open CLI"           │
                    │  • IPC-сервер (Unix socket)    │
                    └───────────┬──────────────────┘
                                │ Unix Domain Socket
                                │ ~/.local/state/startwatch/sock
                                │
                    ┌───────────▼──────────────────┐
                    │         CLI binary            │
                    │   (тот же бинарник,           │
                    │    другой subcommand)          │
                    │                               │
                    │  startwatch status / check /   │
                    │  start / restart / config ...  │
                    └──────────────────────────────┘
                                │
                    ┌───────────▼──────────────────┐
                    │        Config (JSON)          │
                    │  ~/.config/startwatch/        │
                    │  ├── config.json              │
                    │  └── (будущее: config.toml)   │
                    └──────────────────────────────┘
                                │
                    ┌───────────▼──────────────────┐
                    │     State / Cache / Logs      │
                    │  ~/.local/state/startwatch/   │
                    │  ├── sock                     │
                    │  ├── last_check.json          │
                    │  └── history.log              │
                    └──────────────────────────────┘
```

**Один бинарник**, два режима:
- `startwatch daemon` — запускает menu bar agent (LaunchAgent вызывает это)
- `startwatch <command>` — CLI-режим, общается с daemon через socket или работает standalone

---

## Конфиг

```
~/.config/startwatch/config.json
```

```json
{
    "terminal": "warp",
    "checkIntervalMinutes": 180,
    "notifications": {
        "enabled": true,
        "onlyOnFailure": true,
        "sound": true
    },
    "services": [
        {
            "name": "Redis",
            "check": { "type": "port", "value": "6379", "timeout": 3 },
            "start": "brew services start redis",
            "restart": "brew services restart redis",
            "tags": ["infra"]
        },
        {
            "name": "Backend API",
            "check": { "type": "http", "value": "http://localhost:3000/health", "timeout": 5 },
            "start": "cd ~/projects/backend && npm start",
            "cwd": "~/projects/backend",
            "tags": ["app"]
        },
        {
            "name": "Postgres",
            "check": { "type": "port", "value": "5432" },
            "start": "brew services start postgresql@15",
            "restart": "brew services restart postgresql@15",
            "tags": ["infra", "db"]
        },
        {
            "name": "Worker",
            "check": { "type": "command", "value": "pgrep -f 'celery worker'" },
            "start": "cd ~/projects && celery -A tasks worker --detach",
            "tags": ["app"]
        }
    ]
}
```

Поле `terminal` — одно из:

| Значение | Что откроется |
|----------|--------------|
| `"warp"` | Warp |
| `"iterm"` | iTerm2 |
| `"terminal"` | Apple Terminal |
| `"alacritty"` | Alacritty |
| `"kitty"` | Kitty |
| `"/path/to/app"` | Любое .app |

---

## Структура проекта

```
StartWatch/
├── Package.swift
├── README.md
├── config.example.json
├── com.user.startwatch.plist
│
├── Sources/
│   └── StartWatch/
│       │
│       ├── main.swift                    # Точка входа, роутинг команд
│       │
│       ├── CLI/                          # CLI-интерфейс
│       │   ├── CLIRouter.swift           # Парсинг аргументов, dispatch
│       │   ├── Commands/
│       │   │   ├── StatusCommand.swift   # startwatch status
│       │   │   ├── CheckCommand.swift    # startwatch check
│       │   │   ├── StartCommand.swift    # startwatch start <name>
│       │   │   ├── RestartCommand.swift  # startwatch restart <name|all>
│       │   │   ├── ConfigCommand.swift   # startwatch config
│       │   │   ├── LogCommand.swift      # startwatch log
│       │   │   ├── DoctorCommand.swift   # startwatch doctor
│       │   │   └── DaemonCommand.swift   # startwatch daemon
│       │   └── Formatting/
│       │       ├── ANSIColors.swift      # Цвета для терминала
│       │       ├── TableFormatter.swift  # Красивые таблицы
│       │       └── ReportBuilder.swift   # Генерация отчёта
│       │
│       ├── Daemon/                       # Menu bar agent
│       │   ├── AppDelegate.swift         # NSApplication setup
│       │   ├── MenuBarController.swift   # Иконка и меню
│       │   ├── CheckScheduler.swift      # Таймер проверок
│       │   └── IPCServer.swift           # Unix socket сервер
│       │
│       ├── Core/                         # Общая логика
│       │   ├── Config.swift              # Модели конфига + загрузка
│       │   ├── ServiceChecker.swift      # Проверки (process/port/http/cmd)
│       │   ├── ServiceRunner.swift       # Запуск/рестарт сервисов
│       │   ├── CheckResult.swift         # Модель результата
│       │   ├── StateManager.swift        # Сохранение состояния на диск
│       │   └── HistoryLogger.swift       # Лог проверок
│       │
│       ├── Notifications/
│       │   └── NotificationManager.swift # UNUserNotificationCenter
│       │
│       ├── Terminal/
│       │   ├── TerminalLauncher.swift    # Открытие терминала
│       │   └── Terminals/
│       │       ├── WarpTerminal.swift
│       │       ├── ITermTerminal.swift
│       │       ├── AppleTerminal.swift
│       │       ├── AlacrittyTerminal.swift
│       │       ├── KittyTerminal.swift
│       │       └── TerminalProtocol.swift
│       │
│       └── IPC/
│           ├── IPCClient.swift           # CLI → Daemon
│           ├── IPCServer.swift           # Daemon → CLI
│           └── IPCMessage.swift          # Протокол сообщений
│
└── Tests/
    └── StartWatchTests/
        ├── ConfigTests.swift
        ├── ServiceCheckerTests.swift
        └── FormattingTests.swift
```

---

## Роли каждого файла

### main.swift — Точка входа

```swift
import AppKit

@main
struct StartWatchEntry {
    static func main() {
        let args = CommandLine.arguments.dropFirst()
        let command = args.first ?? "status"

        if command == "daemon" {
            // Запуск как menu bar app
            DaemonCommand.run()
        } else {
            // CLI-режим
            CLIRouter.route(arguments: Array(args))
        }
    }
}
```

Один бинарник, два режима. Если вызвали `startwatch daemon` — запускается GUI-агент. Всё остальное — CLI.

---

### CLI/CLIRouter.swift — Роутер команд

```swift
import Foundation

enum CLIRouter {
    static func route(arguments: [String]) {
        let command = arguments.first ?? "status"
        let rest = Array(arguments.dropFirst())

        switch command {
        case "status", "s":
            StatusCommand.run(args: rest)
        case "check", "c":
            CheckCommand.run(args: rest)
        case "start":
            StartCommand.run(args: rest)
        case "restart":
            RestartCommand.run(args: rest)
        case "config":
            ConfigCommand.run(args: rest)
        case "log":
            LogCommand.run(args: rest)
        case "doctor":
            DoctorCommand.run(args: rest)
        case "help", "-h", "--help":
            printHelp()
        case "version", "-v", "--version":
            print("StartWatch 1.0.0")
        default:
            print("Unknown command: \(command)")
            printHelp()
            exit(1)
        }
    }

    static func printHelp() {
        print("""
        \(ANSIColors.bold)StartWatch\(ANSIColors.reset) — service monitor for macOS

        \(ANSIColors.bold)USAGE:\(ANSIColors.reset)
            startwatch <command> [options]

        \(ANSIColors.bold)COMMANDS:\(ANSIColors.reset)
            status, s          Show status of all services
            check, c           Run checks now and show results
            start <name>       Start a service
            restart <name|all> Restart a service or all failed
            config             Open config in $EDITOR
            log                Show check history
            doctor             Diagnose StartWatch itself
            daemon             Start menu bar agent (internal)

        \(ANSIColors.bold)OPTIONS:\(ANSIColors.reset)
            --json             Output as JSON
            --tag <tag>        Filter by tag
            --no-color         Disable colors

        \(ANSIColors.bold)CONFIG:\(ANSIColors.reset)
            \(ConfigManager.configURL.path)
        """)
    }
}
```

---

### CLI/Commands/StatusCommand.swift — Показ статуса

Сначала пытается получить данные от daemon (через IPC). Если daemon не запущен — делает проверку сам.

```swift
import Foundation

enum StatusCommand {
    static func run(args: [String]) {
        let jsonOutput = args.contains("--json")
        let tagFilter = Self.extractTag(from: args)

        // Попробовать получить кэшированные данные от daemon
        if let cached = IPCClient.getLastResults() {
            let filtered = filterByTag(cached, tag: tagFilter)
            if jsonOutput {
                printJSON(filtered)
            } else {
                ReportBuilder.printStatusReport(filtered)
            }
            return
        }

        // Daemon не запущен — проверяем сами
        guard let config = ConfigManager.load() else {
            print("\(ANSIColors.red)Error: No config found.\(ANSIColors.reset)")
            print("Run: startwatch config")
            exit(1)
        }

        print("\(ANSIColors.dim)Checking services...\(ANSIColors.reset)")

        let semaphore = DispatchSemaphore(value: 0)
        var results: [CheckResult] = []

        Task {
            results = await ServiceChecker.checkAll(services: config.services)
            semaphore.signal()
        }
        semaphore.wait()

        let filtered = filterByTag(results, tag: tagFilter)

        if jsonOutput {
            printJSON(filtered)
        } else {
            ReportBuilder.printStatusReport(filtered)
        }

        // Exit code = количество упавших
        let failCount = filtered.filter { !$0.isRunning }.count
        exit(Int32(failCount))
    }

    private static func extractTag(from args: [String]) -> String? {
        guard let idx = args.firstIndex(of: "--tag"),
              idx + 1 < args.count else { return nil }
        return args[idx + 1]
    }

    private static func filterByTag(_ results: [CheckResult], tag: String?) -> [CheckResult] {
        guard let tag = tag else { return results }
        return results.filter { $0.service.tags?.contains(tag) ?? false }
    }

    private static func printJSON(_ results: [CheckResult]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        if let data = try? encoder.encode(results.map { $0.toJSON() }),
           let str = String(data: data, encoding: .utf8) {
            print(str)
        }
    }
}
```

---

### CLI/Commands/CheckCommand.swift — Принудительная проверка

```swift
import Foundation

enum CheckCommand {
    static func run(args: [String]) {
        // Если daemon запущен — попросить его перепроверить
        if IPCClient.isConnected() {
            IPCClient.send(.triggerCheck)
            print("\(ANSIColors.green)✓\(ANSIColors.reset) Check triggered via daemon")
            // Подождать и показать результат
            Thread.sleep(forTimeInterval: 3)
            StatusCommand.run(args: args)
            return
        }

        // Иначе — как status, но всегда свежая проверка
        StatusCommand.run(args: args)
    }
}
```

---

### CLI/Commands/StartCommand.swift

```swift
import Foundation

enum StartCommand {
    static func run(args: [String]) {
        guard let name = args.first else {
            print("Usage: startwatch start <service-name>")
            exit(1)
        }

        guard let config = ConfigManager.load() else {
            print("\(ANSIColors.red)No config found\(ANSIColors.reset)")
            exit(1)
        }

        // Fuzzy match по имени
        guard let service = config.services.first(where: {
            $0.name.lowercased() == name.lowercased() ||
            $0.name.lowercased().contains(name.lowercased())
        }) else {
            print("\(ANSIColors.red)Service '\(name)' not found\(ANSIColors.reset)")
            print("Available: \(config.services.map(\.name).joined(separator: ", "))")
            exit(1)
        }

        guard let startCmd = service.start else {
            print("\(ANSIColors.yellow)No start command for '\(service.name)'\(ANSIColors.reset)")
            exit(1)
        }

        print("\(ANSIColors.cyan)Starting \(service.name)...\(ANSIColors.reset)")
        print("\(ANSIColors.dim)$ \(startCmd)\(ANSIColors.reset)\n")

        ServiceRunner.exec(command: startCmd, cwd: service.cwd)
    }
}
```

---

### CLI/Commands/RestartCommand.swift

```swift
import Foundation

enum RestartCommand {
    static func run(args: [String]) {
        let target = args.first ?? "all"

        guard let config = ConfigManager.load() else {
            print("\(ANSIColors.red)No config found\(ANSIColors.reset)")
            exit(1)
        }

        if target == "all" || target == "failed" {
            // Проверяем и перезапускаем только упавшие
            let semaphore = DispatchSemaphore(value: 0)
            var results: [CheckResult] = []
            Task {
                results = await ServiceChecker.checkAll(services: config.services)
                semaphore.signal()
            }
            semaphore.wait()

            let failed = results.filter { !$0.isRunning }
            if failed.isEmpty {
                print("\(ANSIColors.green)All services are running!\(ANSIColors.reset)")
                return
            }

            for result in failed {
                let cmd = result.service.restart ?? result.service.start
                guard let command = cmd else {
                    print("\(ANSIColors.yellow)⚠ \(result.service.name): no start/restart command\(ANSIColors.reset)")
                    continue
                }
                print("\(ANSIColors.cyan)🔄 \(result.service.name)\(ANSIColors.reset)")
                print("\(ANSIColors.dim)$ \(command)\(ANSIColors.reset)")
                ServiceRunner.run(command: command, cwd: result.service.cwd)
                print()
            }
        } else {
            // Конкретный сервис
            StartCommand.run(args: args)
        }
    }
}
```

---

### CLI/Commands/ConfigCommand.swift

```swift
import Foundation

enum ConfigCommand {
    static func run(args: [String]) {
        let configPath = ConfigManager.configURL.path

        if !FileManager.default.fileExists(atPath: configPath) {
            ConfigManager.createExample()
            print("Created example config at: \(configPath)")
        }

        if args.contains("--path") {
            print(configPath)
            return
        }

        if args.contains("--show") {
            if let content = try? String(contentsOfFile: configPath) {
                print(content)
            }
            return
        }

        // Открыть в $EDITOR
        let editor = ProcessInfo.processInfo.environment["EDITOR"] ?? "nano"
        print("\(ANSIColors.dim)Opening in \(editor)...\(ANSIColors.reset)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [editor, configPath]
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError
        try? process.run()
        process.waitUntilExit()
    }
}
```

---

### CLI/Commands/DoctorCommand.swift

```swift
import Foundation

enum DoctorCommand {
    static func run(args: [String]) {
        print("\(ANSIColors.bold)StartWatch Doctor\(ANSIColors.reset)\n")

        // 1. Конфиг
        checkItem("Config exists") {
            FileManager.default.fileExists(atPath: ConfigManager.configURL.path)
        }

        // 2. Конфиг парсится
        var config: AppConfig?
        checkItem("Config is valid JSON") {
            config = ConfigManager.load()
            return config != nil
        }

        // 3. Daemon запущен
        checkItem("Daemon is running") {
            IPCClient.isConnected()
        }

        // 4. LaunchAgent установлен
        let plistPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.user.startwatch.plist").path
        checkItem("LaunchAgent installed") {
            FileManager.default.fileExists(atPath: plistPath)
        }

        // 5. Терминал доступен
        if let config = config {
            let terminal = config.terminal ?? "warp"
            checkItem("Terminal '\(terminal)' available") {
                TerminalLauncher.isAvailable(terminal: terminal)
            }
        }

        // 6. Нотификации
        checkItem("Notification permission") {
            let semaphore = DispatchSemaphore(value: 0)
            var granted = false
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                granted = settings.authorizationStatus == .authorized
                semaphore.signal()
            }
            semaphore.wait()
            return granted
        }

        print()
        if let config = config {
            print("Services configured: \(config.services.count)")
            for svc in config.services {
                print("  • \(svc.name) [\(svc.check.type.rawValue):\(svc.check.value)]")
            }
        }
    }

    private static func checkItem(_ name: String, check: () -> Bool) {
        let ok = check()
        let icon = ok ? "\(ANSIColors.green)✓\(ANSIColors.reset)" : "\(ANSIColors.red)✗\(ANSIColors.reset)"
        print("  \(icon) \(name)")
    }
}
```

---

### CLI/Commands/DaemonCommand.swift — Запуск GUI

```swift
import AppKit

enum DaemonCommand {
    static func run() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)

        let delegate = AppDelegate()
        app.delegate = delegate

        app.run()
    }
}
```

---

### CLI/Commands/LogCommand.swift

```swift
import Foundation

enum LogCommand {
    static func run(args: [String]) {
        let logPath = StateManager.historyURL.path

        guard FileManager.default.fileExists(atPath: logPath) else {
            print("No history yet. Run: startwatch check")
            return
        }

        let lines = args.contains("--all") ? 1000 : 50

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tail")
        process.arguments = ["-n", "\(lines)", logPath]
        process.standardOutput = FileHandle.standardOutput
        try? process.run()
        process.waitUntilExit()
    }
}
```

---

### CLI/Formatting/ANSIColors.swift

```swift
enum ANSIColors {
    static let reset   = "\u{001B}[0m"
    static let bold    = "\u{001B}[1m"
    static let dim     = "\u{001B}[2m"
    static let red     = "\u{001B}[31m"
    static let green   = "\u{001B}[32m"
    static let yellow  = "\u{001B}[33m"
    static let cyan    = "\u{001B}[36m"
    static let white   = "\u{001B}[37m"

    static let bgRed   = "\u{001B}[41m"
    static let bgGreen = "\u{001B}[42m"

    static var isEnabled: Bool = {
        // Отключаем цвета если не терминал или если --no-color
        guard isatty(STDOUT_FILENO) != 0 else { return false }
        return !CommandLine.arguments.contains("--no-color")
    }()

    static func colored(_ text: String, _ color: String) -> String {
        isEnabled ? "\(color)\(text)\(reset)" : text
    }
}
```

---

### CLI/Formatting/ReportBuilder.swift

```swift
import Foundation

enum ReportBuilder {
    static func printStatusReport(_ results: [CheckResult]) {
        let c = ANSIColors.self

        print()
        print("\(c.bold)  StartWatch Status\(c.reset)")
        print("  \(c.dim)\(formatDate(Date()))\(c.reset)")
        print()

        let maxName = results.map(\.service.name.count).max() ?? 10

        for result in results {
            let icon = result.isRunning
                ? c.colored("✅", c.green)
                : c.colored("❌", c.red)

            let name = result.service.name.padding(toLength: maxName, withPad: " ", startingAt: 0)

            let status = result.isRunning
                ? c.colored("running", c.green)
                : c.colored("down", c.red)

            let detail = c.colored(result.detail, c.dim)

            print("  \(icon)  \(name)  \(status)  \(detail)")

            if !result.isRunning, let start = result.service.start {
                print("  \(c.dim)     ➜ \(start)\(c.reset)")
            }
        }

        let running = results.filter(\.isRunning).count
        let total = results.count
        print()

        if running == total {
            print("  \(c.colored("All \(total) services running ✓", c.green))")
        } else {
            let failed = total - running
            print("  \(c.colored("\(failed) of \(total) services down", c.red))")
            print("  \(c.dim)Run: startwatch restart all\(c.reset)")
        }
        print()
    }

    private static func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f.string(from: date)
    }
}
```

Вот что увидит пользователь:

```
  StartWatch Status
  2024-12-20 14:32:01

  ✅  Redis          running  Port 6379 open
  ❌  Backend API    down     HTTP error: Connection refused
       ➜ cd ~/projects/backend && npm start
  ✅  Postgres       running  Port 5432 open
  ❌  Worker         down     Exit 1: no process found
       ➜ cd ~/projects && celery -A tasks worker --detach

  2 of 4 services down
  Run: startwatch restart all
```

---

### Terminal/TerminalProtocol.swift

```swift
import Foundation

protocol TerminalApp {
    static var identifier: String { get }
    static var bundleID: String { get }

    /// Открыть терминал и выполнить команду
    static func open(command: String) throws

    /// Проверить что приложение установлено
    static func isInstalled() -> Bool
}

extension TerminalApp {
    static func isInstalled() -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil
    }
}
```

---

### Terminal/TerminalLauncher.swift

```swift
import Foundation

enum TerminalLauncher {

    static func openCLI(config: AppConfig) {
        let terminal = config.terminal ?? "warp"
        let command = "startwatch status"

        do {
            switch terminal.lowercased() {
            case "warp":
                try WarpTerminal.open(command: command)
            case "iterm", "iterm2":
                try ITermTerminal.open(command: command)
            case "terminal", "apple":
                try AppleTerminal.open(command: command)
            case "alacritty":
                try AlacrittyTerminal.open(command: command)
            case "kitty":
                try KittyTerminal.open(command: command)
            default:
                // Пользовательский путь к .app
                try GenericTerminal.open(appPath: terminal, command: command)
            }
        } catch {
            print("Failed to open terminal: \(error)")
            // Fallback — Apple Terminal
            try? AppleTerminal.open(command: command)
        }
    }

    static func isAvailable(terminal: String) -> Bool {
        switch terminal.lowercased() {
        case "warp":          return WarpTerminal.isInstalled()
        case "iterm", "iterm2": return ITermTerminal.isInstalled()
        case "terminal":      return true
        case "alacritty":     return AlacrittyTerminal.isInstalled()
        case "kitty":         return KittyTerminal.isInstalled()
        default:              return FileManager.default.fileExists(atPath: terminal)
        }
    }
}
```

---

### Terminal/Terminals/WarpTerminal.swift

```swift
import Foundation

enum WarpTerminal: TerminalApp {
    static let identifier = "warp"
    static let bundleID = "dev.warp.Warp-Stable"

    static func open(command: String) throws {
        // Warp поддерживает launch configurations и `warp://` URL scheme
        // Но самый надёжный способ — через AppleScript с `do script`
        // Warp поддерживает `do script` как и Terminal.app

        let script = """
        tell application "Warp"
            activate
        end tell
        delay 0.5
        tell application "System Events"
            tell process "Warp"
                -- Warp: новый таб
                keystroke "t" using command down
                delay 0.3
                -- Ввод команды
                keystroke "\(command.replacingOccurrences(of: "\"", with: "\\\""))"
                key code 36
            end tell
        end tell
        """

        // Более надёжный вариант: создать temp скрипт и открыть
        let scriptFile = StateManager.stateDir
            .appendingPathComponent("open_cli.sh")
        let content = """
        #!/bin/zsh
        clear
        \(command)
        exec zsh
        """
        try content.write(to: scriptFile, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: scriptFile.path
        )

        // open -a Warp scriptFile — Warp выполнит скрипт в новом табе
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Warp", scriptFile.path]
        try process.run()
        process.waitUntilExit()
    }
}
```

---

### Terminal/Terminals/ITermTerminal.swift

```swift
import Foundation

enum ITermTerminal: TerminalApp {
    static let identifier = "iterm"
    static let bundleID = "com.googlecode.iterm2"

    static func open(command: String) throws {
        let escaped = command.replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "iTerm"
            activate
            create window with default profile command "zsh -c \\"\(escaped); exec zsh\\""
        end tell
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try process.run()
        process.waitUntilExit()
    }
}
```

---

### Terminal/Terminals/AppleTerminal.swift

```swift
import Foundation

enum AppleTerminal: TerminalApp {
    static let identifier = "terminal"
    static let bundleID = "com.apple.Terminal"

    static func open(command: String) throws {
        let escaped = command.replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "Terminal"
            activate
            do script "\(escaped)"
        end tell
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try process.run()
        process.waitUntilExit()
    }
}
```

---

### Daemon/MenuBarController.swift — с кнопкой Open CLI

```swift
import AppKit

class MenuBarController {
    private var statusItem: NSStatusItem!
    private var lastResults: [CheckResult] = []
    private var config: AppConfig?

    var onCheckNow: (() -> Void)?
    var onOpenCLI: (() -> Void)?
    var onOpenConfig: (() -> Void)?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon(allOk: true)
        buildMenu()
    }

    func updateConfig(_ config: AppConfig) {
        self.config = config
    }

    func update(results: [CheckResult]) {
        self.lastResults = results
        let allOk = results.allSatisfy(\.isRunning)
        updateIcon(allOk: allOk)
        buildMenu()
    }

    private func updateIcon(allOk: Bool) {
        guard let button = statusItem.button else { return }

        if #available(macOS 11.0, *) {
            let symbolName = allOk
                ? "checkmark.circle.fill"
                : "exclamationmark.triangle.fill"
            let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "StartWatch")
            image?.isTemplate = true
            button.image = image
        } else {
            button.title = allOk ? "●" : "◐"
        }
    }

    private func buildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        // Заголовок
        let header = NSMenuItem(title: "StartWatch", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        // Время последней проверки
        if let date = lastResults.first?.checkedAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            let timeItem = NSMenuItem(
                title: "  Last check: \(formatter.string(from: date))",
                action: nil, keyEquivalent: ""
            )
            timeItem.isEnabled = false
            menu.addItem(timeItem)
        }

        menu.addItem(NSMenuItem.separator())

        // Сервисы
        if lastResults.isEmpty {
            let item = NSMenuItem(title: "  No checks yet", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            for result in lastResults {
                let icon = result.isRunning ? "✅" : "❌"
                let item = NSMenuItem(
                    title: "\(icon)  \(result.service.name)",
                    action: nil,
                    keyEquivalent: ""
                )
                item.toolTip = "\(result.detail)\n\(result.service.check.type.rawValue): \(result.service.check.value)"
                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // ★ ГЛАВНАЯ КНОПКА — Open CLI
        let terminalName = config?.terminal?.capitalized ?? "Terminal"
        let openCLI = NSMenuItem(
            title: "Open CLI in \(terminalName)",
            action: #selector(openCLIClicked),
            keyEquivalent: "t"
        )
        openCLI.keyEquivalentModifierMask = [.command]
        openCLI.target = self
        menu.addItem(openCLI)

        // Check Now
        let checkNow = NSMenuItem(
            title: "Check Now",
            action: #selector(checkNowClicked),
            keyEquivalent: "r"
        )
        checkNow.keyEquivalentModifierMask = [.command]
        checkNow.target = self
        menu.addItem(checkNow)

        menu.addItem(NSMenuItem.separator())

        // Open Config
        let openConfig = NSMenuItem(
            title: "Open Config…",
            action: #selector(openConfigClicked),
            keyEquivalent: ","
        )
        openConfig.keyEquivalentModifierMask = [.command]
        openConfig.target = self
        menu.addItem(openConfig)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quit = NSMenuItem(
            title: "Quit StartWatch",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quit)

        statusItem.menu = menu
    }

    @objc private func openCLIClicked() {
        onOpenCLI?()
    }

    @objc private func checkNowClicked() {
        onCheckNow?()
    }

    @objc private func openConfigClicked() {
        onOpenConfig?()
    }
}
```

---

### Daemon/AppDelegate.swift — Связывает всё

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController!
    private var scheduler: CheckScheduler!
    private var notifications = NotificationManager.shared
    private var config: AppConfig?
    private var lastResults: [CheckResult] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBar = MenuBarController()

        loadConfig()

        // Связываем menu bar
        menuBar.onCheckNow = { [weak self] in self?.runCheck() }
        menuBar.onOpenCLI = { [weak self] in self?.openCLI() }
        menuBar.onOpenConfig = { [weak self] in self?.openConfig() }

        // Связываем нотификации
        notifications.onOpenReport = { [weak self] in self?.openCLI() }
        notifications.onRestartFailed = { [weak self] in self?.restartFailed() }

        // Таймер
        let interval = TimeInterval((config?.checkIntervalMinutes ?? 180) * 60)
        scheduler = CheckScheduler(interval: interval) { [weak self] in
            self?.runCheck()
        }

        // Первая проверка — через 15 секунд
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            self?.runCheck()
        }
    }

    private func loadConfig() {
        config = ConfigManager.load()
        if let config = config {
            menuBar.updateConfig(config)
        }
    }

    private func runCheck() {
        guard let config = config else {
            loadConfig()
            return
        }

        Task {
            let results = await ServiceChecker.checkAll(services: config.services)

            await MainActor.run {
                self.lastResults = results
                self.menuBar.update(results: results)

                // Сохранить на диск (для CLI)
                StateManager.saveLastResults(results)
                HistoryLogger.log(results)

                // Уведомление
                let failed = results.filter { !$0.isRunning }
                if !failed.isEmpty && (config.notifications?.enabled ?? true) {
                    self.notifications.sendAlert(failedServices: failed)
                }
            }
        }
    }

    // ★ Открыть CLI в настроенном терминале
    private func openCLI() {
        guard let config = config else { return }
        TerminalLauncher.openCLI(config: config)
    }

    private func openConfig() {
        NSWorkspace.shared.open(ConfigManager.configURL)
    }

    private func restartFailed() {
        guard let config = config else { return }
        // Открываем терминал с командой restart
        let terminal = config.terminal ?? "warp"
        let command = "startwatch restart all"
        // Используем тот же TerminalLauncher
        do {
            switch terminal.lowercased() {
            case "warp": try WarpTerminal.open(command: command)
            case "iterm": try ITermTerminal.open(command: command)
            default: try AppleTerminal.open(command: command)
            }
        } catch {
            print("Failed to open terminal: \(error)")
        }
    }
}
```

---

### Daemon/CheckScheduler.swift

```swift
import Foundation

class CheckScheduler {
    private var timer: Timer?

    init(interval: TimeInterval, action: @escaping () -> Void) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            action()
        }
        // Убеждаемся что таймер работает даже когда меню открыто
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    deinit {
        timer?.invalidate()
    }
}
```

---

### Core/StateManager.swift

```swift
import Foundation

enum StateManager {
    static let stateDir: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/state/startwatch")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static let lastResultsURL = stateDir.appendingPathComponent("last_check.json")
    static let historyURL = stateDir.appendingPathComponent("history.log")
    static let socketURL = stateDir.appendingPathComponent("sock")

    static func saveLastResults(_ results: [CheckResult]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(results.map { $0.toCodable() }) {
            try? data.write(to: lastResultsURL)
        }
    }

    static func loadLastResults() -> [CodableCheckResult]? {
        guard let data = try? Data(contentsOf: lastResultsURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([CodableCheckResult].self, from: data)
    }
}
```

---

### IPC/IPCClient.swift

Для CLI → Daemon коммуникации. Пока простейшая реализация через файл (last_check.json). В будущем — Unix socket.

```swift
import Foundation

enum IPCClient {
    /// Получить результаты из кэша daemon-а
    static func getLastResults() -> [CheckResult]? {
        guard let cached = StateManager.loadLastResults() else { return nil }

        // Если данные старше 4 часов — считаем невалидными
        if let first = cached.first,
           Date().timeIntervalSince(first.checkedAt) > 4 * 3600 {
            return nil
        }

        // Нужен конфиг чтобы восстановить полные CheckResult
        guard let config = ConfigManager.load() else { return nil }

        return cached.compactMap { cached -> CheckResult? in
            guard let service = config.services.first(where: { $0.name == cached.serviceName }) else {
                return nil
            }
            return CheckResult(
                service: service,
                isRunning: cached.isRunning,
                detail: cached.detail,
                checkedAt: cached.checkedAt
            )
        }
    }

    static func isConnected() -> Bool {
        // Проверяем что daemon процесс жив
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-f", "startwatch daemon"]
        process.standardOutput = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    }

    static func send(_ message: IPCMessage) {
        // TODO: Unix socket IPC
        // Пока — через файл-флаг
        switch message {
        case .triggerCheck:
            let flagFile = StateManager.stateDir.appendingPathComponent("trigger_check")
            FileManager.default.createFile(atPath: flagFile.path, contents: nil)
        }
    }
}
```

---

### IPC/IPCMessage.swift

```swift
enum IPCMessage: Codable {
    case triggerCheck
    case getStatus
    case restartService(name: String)
    case restartAllFailed
}
```

---

## Итого: полная карта ролей

```
Файл                              Роль
─────────────────────────────────────────────────────────────────
main.swift                        Роутинг: daemon vs CLI
│
├── CLI/
│   ├── CLIRouter.swift           Парсинг команд, dispatch
│   ├── Commands/
│   │   ├── StatusCommand         Показать текущий статус (кэш или live)
│   │   ├── CheckCommand          Запустить проверку прямо сейчас
│   │   ├── StartCommand          Запустить конкретный сервис
│   │   ├── RestartCommand        Перезапустить один или все упавшие
│   │   ├── ConfigCommand         Открыть/показать конфиг
│   │   ├── LogCommand            Показать историю проверок
│   │   ├── DoctorCommand         Самодиагностика
│   │   └── DaemonCommand         Запустить menu bar agent
│   └── Formatting/
│       ├── ANSIColors            Цвета терминала
│       ├── TableFormatter        Форматирование таблиц
│       └── ReportBuilder         Генерация красивого отчёта
│
├── Daemon/
│   ├── AppDelegate               Инициализация agent, связи между компонентами
│   ├── MenuBarController         Иконка в menu bar + меню + кнопка "Open CLI"
│   └── CheckScheduler            Таймер периодических проверок
│
├── Core/
│   ├── Config                    Модели конфига, парсинг JSON, создание примера
│   ├── ServiceChecker            4 типа проверок: process/port/http/command
│   ├── ServiceRunner             Выполнение start/restart команд
│   ├── CheckResult               Модель результата проверки
│   ├── StateManager              Чтение/запись состояния на диск
│   └── HistoryLogger             Аппенд в лог-файл
│
├── Notifications/
│   └── NotificationManager       Нативные macOS нотификации с кнопками действий
│
├── Terminal/
│   ├── TerminalLauncher          Роутер: какой терминал открыть
│   └── Terminals/
│       ├── TerminalProtocol      Интерфейс для терминалов
│       ├── WarpTerminal          Открытие Warp
│       ├── ITermTerminal         Открытие iTerm2
│       ├── AppleTerminal         Открытие Terminal.app
│       ├── AlacrittyTerminal     Открытие Alacritty
│       └── KittyTerminal         Открытие Kitty
│
└── IPC/
    ├── IPCClient                 CLI → Daemon (чтение кэша, отправка команд)
    ├── IPCServer                 Daemon: слушает команды от CLI
    └── IPCMessage                Протокол сообщений
```

---

## Команды для быстрого старта

```bash
# 1. Создать проект
mkdir -p ~/Projects/StartWatch/Sources/StartWatch
cd ~/Projects/StartWatch

# 2. Положить Package.swift и все файлы

# 3. Собрать
swift build -c release

# 4. Установить
cp .build/release/StartWatch /usr/local/bin/startwatch

# 5. Создать конфиг
startwatch config

# 6. Проверить
startwatch doctor

# 7. Первый запуск daemon
startwatch daemon &

# 8. Установить автозапуск
cp com.user.startwatch.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.user.startwatch.plist

# 9. Проверить
startwatch status
```

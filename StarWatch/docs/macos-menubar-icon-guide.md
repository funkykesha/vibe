# macOS Menu Bar Icon — Полное руководство

Задокументировано на основе проблем StarWatch + WorkGuard на macOS 13–26.

---

## Почему иконка не появляется — причины

### 1. Нет `.app` bundle

**Симптом:** `NSStatusItem` создаётся без ошибок, но в menu bar ничего нет.

**Причина:** macOS 13+ требует, чтобы процесс, создающий `NSStatusItem`, был запущен как полноценное приложение с `Info.plist`. CLI-бинарник без bundle не регистрируется как UI-агент.

**Решение:** обязательно собирать `.app` bundle.

---

### 2. Неправильный `Info.plist`

**Минимально необходимые ключи:**

```xml
<key>NSPrincipalClass</key>
<string>NSApplication</string>

<key>LSUIElement</key>
<true/>

<key>CFBundleExecutable</key>
<string>имя_бинарника</string>
```

- `NSPrincipalClass = NSApplication` — macOS регистрирует процесс как UI-агент
- `LSUIElement = YES` — убирает иконку из Dock (чистый menu bar агент)
- Без `LSUIElement` иконка появится в Dock, что некрасиво для daemon-приложений

---

### 3. Запуск через прямой `Process()` вместо `open -a`

**Симптом:** процесс запущен, AppKit загружен, `NSStatusItem` создан, но иконки нет.

**Причина:** macOS отслеживает, как был запущен процесс. Subprocess через `Process()` не проходит регистрацию как UI-агент, даже с `Info.plist`.

**Неправильно:**
```swift
// Прямой запуск бинарника — иконка НЕ появится
let process = Process()
process.executableURL = URL(fileURLWithPath: "/path/to/MyMenuApp.app/Contents/MacOS/binary")
process.arguments = ["--mode", "menu"]
try process.run()
```

**Правильно:**
```swift
// Через open -na — macOS регистрирует как UI-агент
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
process.arguments = ["-na", "/path/to/MyMenuApp.app", "--args", "menu"]
try process.run()
```

Флаги `open`:
- `-n` — открыть новый инстанс (даже если уже запущен)
- `-a` — указать `.app` bundle (macOS регистрирует как UI)
- `--args` — аргументы передаются в `CommandLine.arguments` бинарника

---

### 4. `UNUserNotificationCenter` краш в процессах без bundle

**Симптом:** daemon крашится сразу при старте. Backtrace:
```
UNUserNotificationCenter currentNotificationCenter
NotificationManager.init
DaemonCommand.run
```

**Причина:** `UNUserNotificationCenter.current()` на macOS 26 бросает исключение, если процесс не имеет `Bundle.main.bundleIdentifier`.

**Фикс:**
```swift
private override init() {
    super.init()
    guard Bundle.main.bundleIdentifier != nil else { return }
    setupCategories()
}
```

Применяется везде, где используется `UNUserNotificationCenter`:
```swift
func requestAuthorization() {
    guard Bundle.main.bundleIdentifier != nil else { return }
    UNUserNotificationCenter.current().requestAuthorization(...)
}
```

---

### 5. Устаревший бинарник в `.app` bundle

**Симптом:** обновил `/usr/local/bin/mybinary`, но поведение не изменилось.

**Причина:** `.app` bundle содержит свою копию бинарника в `Contents/MacOS/`. Это отдельный файл.

**install.sh должен обновлять оба:**
```bash
# Основной бинарник
cp .build/release/MyApp /usr/local/bin/myapp

# .app bundle бинарник — отдельная копия!
cp .build/release/MyApp ~/Applications/MyMenuApp.app/Contents/MacOS/myapp
```

---

## Рабочая архитектура: daemon + menu-agent

Проверенная схема (StarWatch, WorkGuard):

```
LaunchAgent plist
    └── /usr/local/bin/myapp daemon        # headless, без UI
            ├── бизнес-логика
            ├── IPC server (файловый polling)
            └── spawnMenuAgent() → open -na ~/Applications/MyMenuApp.app --args menu-agent

~/Applications/MyMenuApp.app/Contents/MacOS/myapp menu-agent
    └── NSApplication (.accessory)
            └── AppDelegate → NSStatusItem + NSMenu
```

**Почему два процесса, а не один:**
- Daemon работает всегда (LaunchAgent с `KeepAlive = true`)
- Menu-agent может быть убит/перезапущен без потери логики
- `NSStatusItem` надёжно отображается только в процессе с `NSApplication.run()`
- Daemon без UI не требует accessibility permissions

---

## Минимальная структура `.app` bundle

```
MyMenuApp.app/
├── Contents/
│   ├── MacOS/
│   │   └── mybinary          ← исполняемый файл
│   └── Info.plist            ← ОБЯЗАТЕЛЕН
```

**Сборка в install.sh:**
```bash
APP="$HOME/Applications/MyMenuApp.app"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/MyApp "$APP/Contents/MacOS/mybinary"
cp Resources/MyMenuApp-Info.plist "$APP/Contents/Info.plist"
```

---

## Минимальный Info.plist для menu bar agent

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.yourname.appname.menu</string>

    <key>CFBundleName</key>
    <string>AppNameMenu</string>

    <key>CFBundleExecutable</key>
    <string>mybinary</string>

    <key>CFBundleVersion</key>
    <string>1.0</string>

    <key>NSPrincipalClass</key>
    <string>NSApplication</string>

    <key>LSUIElement</key>
    <true/>

    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>

    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
```

---

## Минимальный Swift код menu bar agent

```swift
// main.swift — роутинг
let command = CommandLine.arguments.dropFirst().first ?? ""
if command == "menu-agent" {
    MenuAgentCommand.run()
} else {
    // daemon / CLI логика
}

// MenuAgentCommand.swift
enum MenuAgentCommand {
    static func run() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)   // без иконки в Dock
        let delegate = MenuAgentDelegate()
        app.delegate = delegate
        app.run()                              // блокирует, запускает run loop
    }
}

// MenuAgentDelegate.swift
final class MenuAgentDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if #available(macOS 11.0, *) {
            statusItem.button?.image = NSImage(
                systemSymbolName: "checkmark.circle.fill",
                accessibilityDescription: "MyApp"
            )
        } else {
            statusItem.button?.title = "●"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
```

---

## Чеклист отладки

- [ ] `.app` bundle существует с правильной структурой (`Contents/MacOS/`, `Contents/Info.plist`)
- [ ] `Info.plist` содержит `NSPrincipalClass = NSApplication` и `LSUIElement = YES`
- [ ] `CFBundleExecutable` совпадает с именем файла в `Contents/MacOS/`
- [ ] Запуск через `open -na /path/to/App.app` (не прямой путь к бинарнику)
- [ ] Бинарник в `.app` bundle обновлён после пересборки
- [ ] Нет вызовов `UNUserNotificationCenter` в daemon-процессе без bundle
- [ ] `NSStatusItem` создаётся на главном потоке (в `applicationDidFinishLaunching`)
- [ ] Нет дублирующих инстансов с тем же `CFBundleIdentifier`

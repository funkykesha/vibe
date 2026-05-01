# Plan: Notifications + FileWatcher + Thread Safety

## Context

Пользователь хочет:
1. Уведомления macOS с причиной сбоя (из поля `detail`) + уведомления о восстановлении и невалидном конфиге
2. Надёжный FileWatcher на FSEvents вместо polling
3. Thread-safe доступ к `config` через `configQueue` с barrier

Решения согласованы через grill-me сессию.

---

## Решения

| Что | Решение |
|-----|---------|
| Уведомление при падении | Одно на все сервисы, заменяет предыдущее (фиксированный id), с причиной из `detail` |
| Уведомление при восстановлении | "Service Recovered: Redis" |
| Уведомление невалидный конфиг | Да, при каждом сохранении невалидного конфига |
| Флаг | `showFailureDetails: Bool?` в `NotificationsConfig` |
| Уровень | Глобальный |
| При старте демона | Молчать, только записать текущий статус как baseline |
| Визуал / смена иконок | Беклог, не сейчас |

---

## Изменения

### 1. `Sources/StartWatch/Core/FileWatcher.swift` — полная замена

- Удалить Timer polling + все `fw.log` записи
- Следить за **директорией** (`~/.config/startwatch/`), не за файлом — надёжно при атомарных сохранениях любого редактора
- `DispatchSource.makeFileSystemObjectSource` с `eventMask: [.write, .rename]` на директорию на `.main` queue
- При событии проверять mtime целевого файла — фильтр чтобы не реагировать на другие файлы в директории
- Debounce 200ms через `DispatchWorkItem` с cancel предыдущего

```swift
final class FileWatcher {
    private let filePath: String      // целевой файл (для mtime-проверки)
    private let dirPath: String       // директория (для FSEvents)
    private var source: DispatchSourceFileSystemObject?
    private var dirFD: Int32 = -1
    private var lastModified: Date?
    private var debounceItem: DispatchWorkItem?
    // start() → open(dirPath, O_EVTONLY) → makeFileSystemObjectSource на dirFD → resume()
    // eventHandler: проверить mtime filePath, если изменился → scheduleCallback()
    // scheduleCallback() → cancel prev debounceItem → new DispatchWorkItem → asyncAfter(0.2s)
    // stop() → cancel debounce + source.cancel() (cancelHandler закрывает dirFD)
}
```

### 2. `Sources/StartWatch/Core/Config.swift`

Добавить поле в `NotificationsConfig`:
```swift
struct NotificationsConfig: Codable {
    let enabled: Bool?
    let onlyOnFailure: Bool?
    let sound: Bool?
    let showFailureDetails: Bool?  // NEW
}
```

### 3. `Sources/StartWatch/Notifications/NotificationManager.swift`

- Добавить `private let alertIdentifier = "startwatch-services-down"` — фиксированный id для замены предыдущего
- Изменить `sendAlert(failedServices:)` → `sendAlert(failedServices:showDetails:)`
  - 1 сервис: title = "Service Down: Redis", body = detail или "Not running"
  - N сервисов: title = "Services Down (N)", body = "Redis: Port 6379...; Postgres: ..."
  - Использует `alertIdentifier` → заменяет предыдущее уведомление
- Добавить `sendRecovered(services: [CheckResult], sound: Bool)`
  - title = "Service Recovered" / "Services Recovered", body = имена
  - id = "startwatch-services-recovered"
- Добавить `sendConfigInvalid(errors: [String], sound: Bool)`
  - title = "Config Error", body = errors.joined(separator: "; ")
  - id = "startwatch-config-invalid"
- Вынести общий `private func send(content:identifier:)` чтобы не дублировать
- Все методы принимают `sound: Bool` → `content.sound = sound ? .default : nil`
- Caller (`handleNotifications`) читает `config.notifications?.sound == true` и передаёт

### 4. `Sources/StartWatch/Daemon/AppDelegate.swift` (DaemonCoordinator)

**Thread safety:**
```swift
private var _config: AppConfig?
private let configQueue = DispatchQueue(label: "com.startwatch.config", attributes: .concurrent)
private var config: AppConfig? {
    get { configQueue.sync { _config } }
    set { configQueue.sync(flags: .barrier) { self._config = newValue } }  // sync чтобы runCheck() сразу видел новый конфиг
}
```

**`onlyOnFailure` не подавляет "recovered"** — уведомление о восстановлении приходит всегда когда `enabled: true`.

**Убрать fw.log из `watchConfigFile()`** — удалить 5 строк записи в fw.log

**Добавить baseline tracking:**
```swift
private var previousResults: [String: Bool]? = nil  // nil = первый запуск
```

**`reloadConfig()` — уведомление при невалидном конфиге:**
```swift
if !errors.isEmpty {
    if config?.notifications?.enabled == true {
        NotificationManager.shared.sendConfigInvalid(errors: errors)
    }
    return
}
```

**`runCheck()` — добавить `handleNotifications` в `MainActor.run`:**
```swift
await MainActor.run {
    StateManager.saveLastResults(results)
    HistoryLogger.log(results)
    self.handleNotifications(results: results, config: currentConfig)
}
```

**Новый метод `handleNotifications`:**
```swift
private func handleNotifications(results: [CheckResult], config: AppConfig) {
    let currentMap = Dictionary(uniqueKeysWithValues: results.map { ($0.service.name, $0.isRunning) })

    guard config.notifications?.enabled == true else {
        previousResults = currentMap
        return
    }

    guard let previous = previousResults else {
        previousResults = currentMap  // первый запуск — baseline, без уведомлений
        return
    }

    let showDetails = config.notifications?.showFailureDetails == true

    let newlyFailed = results.filter { !$0.isRunning && !$0.isStarting && (previous[$0.service.name] ?? true) }
    let newlyRecovered = results.filter { $0.isRunning && !(previous[$0.service.name] ?? true) }

    if !newlyFailed.isEmpty {
        NotificationManager.shared.sendAlert(failedServices: newlyFailed, showDetails: showDetails)
    }
    if !newlyRecovered.isEmpty {
        NotificationManager.shared.sendRecovered(services: newlyRecovered)
    }

    previousResults = currentMap
}
```

---

### 5. `docs/adr/0001-filewatcher-directory-over-file.md` — создать

ADR фиксирует: почему следим за директорией, а не файлом. Причина — атомарные сохранения редакторов (VSCode, vim) меняют inode, file descriptor на старый файл перестаёт получать события. Directory fd устойчив к этому.

---

## Верификация

1. `swift build` — компилируется без ошибок
2. Запустить демон, отредактировать конфиг → в fw.log ничего не пишется
3. Убить сервис → уведомление "Service Down: X — Port Y not responding"
4. Восстановить сервис → уведомление "Service Recovered: X"
5. Сохранить невалидный конфиг (пустое имя) → уведомление "Config Error: ..."
6. При быстром двойном сохранении — одна перезагрузка (debounce работает)
7. При рестарте демона когда сервис лежит — уведомления нет

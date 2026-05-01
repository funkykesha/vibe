## 1. FileWatcher — FSEvents + Debounce

- [x] 1.1 Rewrite `FileWatcher.swift`: replace Timer with `DispatchSource.makeFileSystemObjectSource` watching the parent directory (`O_EVTONLY`)
- [x] 1.2 Watch `eventMask: [.write, .rename]` on directory fd; in event handler check mtime of target file to filter unrelated changes
- [x] 1.3 Implement debounce: cancel previous `DispatchWorkItem`, schedule new one 200ms later on `.main`
- [x] 1.4 Implement `cancelHandler` that closes the directory fd
- [x] 1.5 Remove all `fw.log` writes from `FileWatcher.swift` and `AppDelegate.swift`

## 2. Config — Thread Safety

- [x] 2.1 Add `private var _config: AppConfig?` backing store to `DaemonCoordinator`
- [x] 2.2 Replace direct `config` property with computed property using `configQueue.sync` for reads and `configQueue.sync(flags: .barrier)` for writes
- [x] 2.3 Verify all existing call sites compile without changes (property interface unchanged)

## 3. Config — showFailureDetails Flag

- [x] 3.1 Add `showFailureDetails: Bool?` field to `NotificationsConfig` in `Config.swift`

## 4. NotificationManager — Expanded API

- [x] 4.1 Add `private let alertIdentifier = "startwatch-services-down"` constant
- [x] 4.2 Refactor `sendAlert(failedServices:)` → `sendAlert(failedServices:showDetails:sound:)` with detail-aware body formatting (single vs multiple service cases)
- [x] 4.3 Extract `private func send(content: UNMutableNotificationContent, identifier: String)` to eliminate duplication
- [x] 4.4 Add `sendRecovered(services: [CheckResult], sound: Bool)` — title "Service Recovered"/"Services Recovered", id "startwatch-services-recovered"
- [x] 4.5 Add `sendConfigInvalid(errors: [String], sound: Bool)` — title "Config Error", id "startwatch-config-invalid"

## 5. DaemonCoordinator — Notification Logic

- [x] 5.1 Add `private var previousResults: [String: Bool]? = nil` to `DaemonCoordinator`
- [x] 5.2 Add `private func handleNotifications(results: [CheckResult], config: AppConfig)` implementing baseline/transition logic
- [x] 5.3 Filter `isStarting: true` from `newlyFailed` (anti-spam)
- [x] 5.4 Ensure `onlyOnFailure` does not suppress recovered notifications
- [x] 5.5 Pass `config.notifications?.sound == true` to all notification send calls
- [x] 5.6 Call `handleNotifications` inside `MainActor.run` block in `runCheck()`
- [x] 5.7 Send `sendConfigInvalid` from `reloadConfig()` when validation fails and `notifications.enabled == true`

## 6. ADR

- [x] 6.1 Create `docs/adr/0001-filewatcher-directory-over-file.md` documenting the directory-vs-file FSEvents decision

## 7. Verification

- [x] 7.1 `swift build` compiles without errors or warnings
- [ ] 7.2 Edit config file with VSCode (atomic save) → daemon reloads exactly once
- [ ] 7.3 Kill a monitored service → notification appears with failure reason
- [ ] 7.4 Restart the service → "Service Recovered" notification appears
- [ ] 7.5 Save invalid config (empty service name) → "Config Error" notification appears
- [ ] 7.6 Rapid double-save (within 200ms) → single reload, not two
- [ ] 7.7 Restart daemon with service already down → no notification on startup
- [x] 7.8 Confirm `~/.config/startwatch/fw.log` is no longer created

## 1. Fix Guards in NotificationManager

- [ ] 1.1 Replace `Bundle.main.bundleIdentifier != nil` with `Bundle.main.bundleURL.pathExtension == "app"` in `private init()` (setupCategories guard)
- [ ] 1.2 Replace same guard in `internal init(onOpenReport:onRestartFailed:skipSetup:)` (setupCategories guard)
- [ ] 1.3 Replace same guard in `send()` method before `UNUserNotificationCenter.current().add(...)`

## 2. Verification

- [ ] 2.1 Run `swift build` — must complete with 0 errors
- [ ] 2.2 Run `swift test` — must complete with 0 crashes and 0 failures
- [ ] 2.3 Confirm all `NotificationManagerTests` pass (no SIGABRT, no signal 6)

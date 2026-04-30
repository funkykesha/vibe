# Plan: Hotreload Verification & Fix

## Context

`config-hotreload-with-validation` change was implemented with all tasks marked done, but end-to-end verification was never run. During debugging we discovered:

1. Original FileWatcher (DispatchSourceFileSystemObject) didn't trigger on atomic file writes
2. Replaced with polling approach (Timer, checks mtime every 0.5s)
3. Debug logging was added to DaemonCommand (fputs) and FileWatcher — needs cleanup
4. **Root problem**: `reloadConfig()` updates `self.config` but never triggers `runCheck()`, so `startwatch status` shows stale cached results until next scheduled check (up to checkIntervalMinutes)

## Changes

### 1. `Sources/StartWatch/Daemon/AppDelegate.swift`

In `reloadConfig()` — add `runCheck()` call after successful config swap:

```swift
private func reloadConfig() {
    guard let newConfig = ConfigManager.load() else {
        print("[Daemon] Failed to reload config")
        return
    }
    let errors = ConfigManager.validate(newConfig)
    if !errors.isEmpty {
        print("[Daemon] Config reload rejected: \(errors.joined(separator: "; "))")
        return
    }
    let oldCount = config?.services.count ?? 0
    let newCount = newConfig.services.count
    config = newConfig
    print("[Daemon] Config reloaded: \(newCount) services (was \(oldCount))")
    runCheck()  // ← ADD THIS: update cached status immediately
}
```

### 2. `Sources/StartWatch/CLI/Commands/DaemonCommand.swift`

Remove debug fputs added during debugging — restore to minimal form:

```swift
enum DaemonCommand {
    static func run() {
        let coordinator = DaemonCoordinator()
        coordinator.start()
        RunLoop.main.run()
    }
}
```

### 3. `Sources/StartWatch/Core/FileWatcher.swift`

Remove verbose startup print (line 21: `"Started polling..."`) — keep error prints only:

```swift
func start(onChange: @escaping () -> Void) {
    guard FileManager.default.fileExists(atPath: filePath) else {
        print("[FileWatcher] File not found: \(filePath)")
        return
    }
    updateLastModified()
    // Remove: print("[FileWatcher] Started polling ...")
    timer = Timer.scheduledTimer(...)
}
```

## Verification

1. `swift build` — no errors
2. `swift test` — 19/19 pass
3. Manual test:
   - Reset config to 4 services
   - Start daemon: `.build/debug/startwatch daemon &`
   - `startwatch status` → "All 4 services"
   - Add 5th service via jq
   - Wait 2 seconds
   - `startwatch status` → "All 5 services" ✓
4. Invalid config test:
   - Edit config: remove `check.value` from one service
   - Wait 2s
   - `startwatch status` → still shows 4 services (old config kept) ✓

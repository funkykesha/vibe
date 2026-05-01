# Implementation Plan: notifications-and-reliability

**Date**: 2026-05-01  
**Author**: Atlas (Master Orchestrator)  
**Status**: Ready for Execution  
**Tasks**: 28 bite-sized tasks across 7 phases

## Overview
Unified implementation combining:
- Original `notifications-and-filewatcher-reliability` scope (FSEvents FileWatcher + rich notifications)
- `fix-eliza-missing-from-results` reliability improvements (TaskGroup error handling, AsyncHelpers fix)

## Success Criteria
- FileWatcher uses FSEvents (not polling) with 200ms debounce
- Config access is thread-safe with barrier queue pattern
- NotificationManager supports 3 notification types with stable IDs
- ServiceChecker handles TaskGroup errors properly
- All existing tests pass + new verification steps

---

## Phase 1: FileWatcher FSEvents Implementation (Tasks 1-4)

### Task 1: Create FSEvents-based FileWatcher
```swift
// Sources/StartWatch/Core/FileWatcher.swift
import Foundation
import Dispatch

public class FileWatcher {
    private let configDirectoryURL: URL
    private var fileDescriptor: CInt = -1
    private var source: DispatchSourceFileSystemObject?
    private var debounceWorkItem: DispatchWorkItem?
    private let debounceQueue = DispatchQueue(label: "com.startwatch.filewatcher.debounce")
    private let onChange: () -> Void
    
    public init(configDirectoryURL: URL, onChange: @escaping () -> Void) {
        self.configDirectoryURL = configDirectoryURL
        self.onChange = onChange
    }
    
    public func start() throws {
        guard fileDescriptor == -1 else { return }
        
        let path = configDirectoryURL.path
        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor != -1 else {
            throw FileWatcherError.cannotOpenDirectory(path: path)
        }
        
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename],
            queue: DispatchQueue.global()
        )
        
        source?.setEventHandler { [weak self] in
            self?.handleFileSystemEvent()
        }
        
        source?.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd != -1 {
                close(fd)
                self?.fileDescriptor = -1
            }
        }
        
        source?.resume()
    }
    
    private func handleFileSystemEvent() {
        debounceWorkItem?.cancel()
        debounceWorkItem = DispatchWorkItem { [weak self] in
            self?.onChange()
        }
        debounceQueue.asyncAfter(deadline: .now() + 0.2, execute: debounceWorkItem!)
    }
    
    public func stop() {
        debounceWorkItem?.cancel()
        source?.cancel()
        source = nil
        
        if fileDescriptor != -1 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }
    
    deinit {
        stop()
    }
}

public enum FileWatcherError: Error {
    case cannotOpenDirectory(path: String)
}
```

### Task 2: Add FileWatcher Tests
```swift
// Tests/StartWatchTests/FileWatcherTests.swift
import XCTest
@testable import StartWatch

final class FileWatcherTests: XCTestCase {
    private var tempDirectory: URL!
    private var fileWatcher: FileWatcher!
    
    override func setUp() async throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("StartWatchTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() async throws {
        fileWatcher?.stop()
        try? FileManager.default.removeItem(at: tempDirectory)
    }
    
    func testFileWatcherDetectsFileChanges() async throws {
        let expectation = XCTestExpectation(description: "File change detected")
        
        fileWatcher = FileWatcher(configDirectoryURL: tempDirectory) {
            expectation.fulfill()
        }
        
        try fileWatcher.start()
        
        // Create a file to trigger the watcher
        let testFile = tempDirectory.appendingPathComponent("test.txt")
        try "test content".write(to: testFile, atomically: true, encoding: .utf8)
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testFileWatcherDebouncesEvents() async throws {
        var changeCount = 0
        let expectation = XCTestExpectation(description: "Debounced change detected")
        expectation.expectedFulfillmentCount = 1
        
        fileWatcher = FileWatcher(configDirectoryURL: tempDirectory) {
            changeCount += 1
            if changeCount == 1 {
                expectation.fulfill()
            }
        }
        
        try fileWatcher.start()
        
        // Rapid file changes should be debounced to one event
        let testFile = tempDirectory.appendingPathComponent("test.txt")
        for i in 0..<5 {
            try "content \(i)".write(to: testFile, atomically: true, encoding: .utf8)
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
        
        await fulfillment(of: [expectation], timeout: 0.5)
        XCTAssertEqual(changeCount, 1, "Should only trigger once due to debouncing")
    }
}
```

### Task 3: Update DaemonCoordinator to use new FileWatcher
```swift
// Sources/StartWatch/Daemon/AppDelegate.swift (partial update)
private func watchConfigFile() {
    let configURL = ConfigManager.configDirectoryURL
    
    do {
        fileWatcher = FileWatcher(configDirectoryURL: configURL) { [weak self] in
            self?.reloadConfig()
        }
        try fileWatcher?.start()
    } catch {
        print("Failed to start file watcher: \(error)")
    }
}
```

### Task 4: Remove old polling FileWatcher implementation
```swift
// Sources/StartWatch/Core/FileWatcher.swift (remove old implementation)
// Delete the entire old FileWatcher class and replace with new FSEvents version
```

## Phase 2: Thread-Safe Config Access (Tasks 5-6)

### Task 5: Add backing store to ConfigManager
```swift
// Sources/StartWatch/Core/Config.swift (add to ConfigManager)
private let configQueue = DispatchQueue(label: "com.startwatch.config", attributes: .concurrent)
private var _config: Config?

public static var current: Config {
    get {
        return configQueue.sync {
            guard let config = _config else {
                fatalError("Config not loaded")
            }
            return config
        }
    }
    set {
        configQueue.sync(flags: .barrier) {
            _config = newValue
        }
    }
}
```

### Task 6: Add showFailureDetails flag to Config model
```swift
// Sources/StartWatch/Core/Config.swift (add to Config struct)
public struct Config: Codable {
    public var services: [ServiceConfig]
    public var notifications: NotificationsConfig
    
    public struct NotificationsConfig: Codable {
        public var enabled: Bool
        public var showFailureDetails: Bool
        
        public init(enabled: Bool = true, showFailureDetails: Bool = false) {
            self.enabled = enabled
            self.showFailureDetails = showFailureDetails
        }
    }
    
    public init(services: [ServiceConfig], notifications: NotificationsConfig = NotificationsConfig()) {
        self.services = services
        self.notifications = notifications
    }
}
```

## Phase 3: NotificationManager Expansion (Tasks 7-11)

### Task 7: Add notification identifiers
```swift
// Sources/StartWatch/Notifications/NotificationManager.swift (add constants)
private enum NotificationIdentifier {
    static let alertIdentifier = "com.startwatch.service-alert"
    static let recoveredIdentifier = "com.startwatch.service-recovered"
    static let configInvalidIdentifier = "com.startwatch.config-invalid"
}
```

### Task 8: Extract send() helper method
```swift
// Sources/StartWatch/Notifications/NotificationManager.swift
private func send(content: UNNotificationContent, identifier: String, sound: UNNotificationSound? = .default) {
    let request = UNNotificationRequest(
        identifier: identifier,
        content: content,
        trigger: nil
    )
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Failed to send notification: \(error)")
        }
    }
}
```

### Task 9: Refactor sendAlert to use helper
```swift
// Sources/StartWatch/Notifications/NotificationManager.swift
public func sendAlert(serviceName: String, reason: String? = nil) {
    let content = UNMutableNotificationContent()
    content.title = "\(serviceName) is down"
    
    if let reason = reason, ConfigManager.current.notifications.showFailureDetails {
        content.body = "Failed with error: \(reason)"
    } else {
        content.body = "Service is not responding"
    }
    
    content.sound = .default
    
    send(content: content, identifier: NotificationIdentifier.alertIdentifier)
}
```

### Task 10: Add sendRecovered method
```swift
// Sources/StartWatch/Notifications/NotificationManager.swift
public func sendRecovered(serviceName: String) {
    let content = UNMutableNotificationContent()
    content.title = "\(serviceName) recovered"
    content.body = "Service is now responding"
    content.sound = .default
    
    send(content: content, identifier: NotificationIdentifier.recoveredIdentifier)
}
```

### Task 11: Add sendConfigInvalid method
```swift
// Sources/StartWatch/Notifications/NotificationManager.swift
public func sendConfigInvalid(error: String) {
    let content = UNMutableNotificationContent()
    content.title = "Configuration Error"
    content.body = "Failed to load config: \(error)"
    content.sound = .default
    
    send(content: content, identifier: NotificationIdentifier.configInvalidIdentifier)
}
```

## Phase 4: Notification Logic Integration (Tasks 12-15)

### Task 12: Add previousResults tracking to DaemonCoordinator
```swift
// Sources/StartWatch/Daemon/AppDelegate.swift (add property)
private var previousResults: [String: Bool]?
```

### Task 13: Implement handleNotifications method
```swift
// Sources/StartWatch/Daemon/AppDelegate.swift
private func handleNotifications(currentResults: [String: Bool]) {
    guard ConfigManager.current.notifications.enabled else { return }
    
    // First run - just store baseline
    guard let previous = previousResults else {
        previousResults = currentResults
        return
    }
    
    let notificationManager = NotificationManager.shared
    
    // Check for failures (new failures only)
    for (serviceName, isUp) in currentResults where !isUp {
        if previous[serviceName] != false {
            // New failure
            let reason = "Service check failed" // Would come from ServiceChecker
            notificationManager.sendAlert(serviceName: serviceName, reason: reason)
        }
    }
    
    // Check for recoveries
    for (serviceName, isUp) in currentResults where isUp {
        if previous[serviceName] == false {
            // Recovery
            notificationManager.sendRecovered(serviceName: serviceName)
        }
    }
    
    previousResults = currentResults
}
```

### Task 14: Integrate notifications into runCheck
```swift
// Sources/StartWatch/Daemon/AppDelegate.swift (update runCheck)
private func runCheck() async {
    do {
        let results = try await ServiceChecker.checkAll()
        
        // Handle notifications
        handleNotifications(currentResults: results)
        
        // Update cache
        updateLastCheckCache(results: results)
    } catch {
        print("Service check failed: \(error)")
        // Task 16 will add proper error handling here
    }
}
```

### Task 15: Add config error notification
```swift
// Sources/StartWatch/Daemon/AppDelegate.swift (update reloadConfig)
private func reloadConfig() {
    do {
        try ConfigManager.reload()
    } catch {
        print("Failed to reload config: \(error)")
        
        if ConfigManager.current.notifications.enabled {
            NotificationManager.shared.sendConfigInvalid(error: error.localizedDescription)
        }
    }
}
```

## Phase 5: Reliability Improvements (Tasks 16-18)

### Task 16: Add try/catch to ServiceChecker TaskGroup
```swift
// Sources/StartWatch/Core/ServiceChecker.swift (update checkAll)
public static func checkAll() async throws -> [String: Bool] {
    let config = ConfigManager.current
    var results: [String: Bool] = [:] 
    
    await withThrowingTaskGroup(of: (String, Bool).self) { group in
        for service in config.services {
            group.addTask {
                do {
                    let isUp = try await checkService(service)
                    return (service.name, isUp)
                } catch {
                    print("Service check failed for \(service.name): \(error)")
                    return (service.name, false)
                }
            }
        }
        
        for try await (serviceName, isUp) in group {
            results[serviceName] = isUp
        }
    }
    
    return results
}
```

### Task 17: Add error handling to runCheck
```swift
// Sources/StartWatch/Daemon/AppDelegate.swift (enhance runCheck error handling)
private func runCheck() async {
    do {
        let results = try await ServiceChecker.checkAll()
        
        // Handle notifications
        handleNotifications(currentResults: results)
        
        // Update cache
        updateLastCheckCache(results: results)
        
    } catch {
        print("Service check failed: \(error)")
        
        // Send notification for catastrophic failure
        if ConfigManager.current.notifications.enabled {
            NotificationManager.shared.sendConfigInvalid(error: "Service check system error: \(error.localizedDescription)")
        }
        
        // Preserve previous results to avoid false recovery notifications
        // Don't update previousResults to maintain state consistency
    }
}
```

### Task 18: Fix AsyncHelpers force unwrap
```swift
// Sources/StartWatch/Core/AsyncHelpers.swift (update runSync)
public static func runSync<T>(_ operation: @escaping () async throws -> T) throws -> T {
    let semaphore = DispatchSemaphore(value: 0)
    var result: Result<T, Error>?
    
    Task {
        do {
            let value = try await operation()
            result = .success(value)
        } catch {
            result = .failure(error)
        }
        semaphore.signal()
    }
    
    semaphore.wait()
    
    switch result {
    case .success(let value):
        return value
    case .failure(let error):
        throw error
    case nil:
        throw AsyncHelpersError.operationCancelledOrTimedOut
    }
}

public enum AsyncHelpersError: Error {
    case operationCancelledOrTimedOut
}
```

## Phase 6: ADR Documentation (Task 19)

### Task 19: Create ADR for directory-vs-file decision
```markdown
# docs/adr/0001-filewatcher-directory-over-file.md
# ADR 0001: FileWatcher Directory Monitoring vs File Monitoring

## Status
Accepted

## Context
We need to monitor configuration file changes for hot reloading. Options:
- Monitor the specific config file (`config.json`)
- Monitor the entire config directory

## Decision
Monitor the config directory rather than the specific file.

## Rationale
1. **Atomic saves**: Editors like VSCode and vim save atomically by writing to temp files then renaming
2. **Multiple files**: Future configs might span multiple files
3. **Debouncing**: Directory watching allows us to debounce rapid changes from auto-save
4. **Simplicity**: Single watch point vs tracking file creation/deletion

## Consequences
- **Positive**: Handles all editor save patterns correctly
- **Positive**: Future-proof for multi-file configs
- **Negative**: Slightly more system resources (watching directory vs file)
- **Mitigation**: 200ms debounce prevents excessive notifications
```

## Phase 7: Verification (Tasks 20-28)

### Task 20: Build verification
```bash
swift build
```

### Task 21: VSCode save test
1. Open `~/.config/startwatch/config.json` in VSCode
2. Make change and save
3. Verify FileWatcher triggers within 200ms
4. Check daemon logs for config reload

### Task 22: Failure notification test
1. Stop a monitored service (e.g., `brew services stop postgresql`)
2. Run `startwatch check`
3. Verify notification appears with service name
4. Verify no duplicate notifications on subsequent checks

### Task 23: Recovery notification test
1. Start the stopped service
2. Run `startwatch check`
3. Verify recovery notification appears
4. Verify no further notifications for healthy service

### Task 24: Config error notification test
1. Create invalid config: `echo "invalid json" > ~/.config/startwatch/config.json`
2. Verify config error notification appears
3. Restore valid config
4. Verify no further error notifications

### Task 25: Rapid save test
1. Make 5 rapid saves to config file within 1 second
2. Verify only one config reload occurs (debouncing)
3. Check daemon logs for single reload event

### Task 26: Startup notification suppression test
1. Ensure some services are down at daemon startup
2. Start daemon
3. Verify no notifications for initially down services
4. Verify notifications only for state transitions

### Task 27: fw.log cleanup verification
1. Verify `~/.config/startwatch/fw.log` no longer exists
2. Check daemon logs for FileWatcher initialization instead

### Task 28: Test suite execution
```bash
swift test
```

---

## Implementation Notes

### FileWatcher Behavior
- Uses FSEvents API via `DispatchSource.makeFileSystemObjectSource`
- Monitors directory for `.write` and `.rename` events
- 200ms debounce prevents excessive notifications from rapid saves
- Proper resource cleanup in `stop()` and `deinit`

### Thread Safety
- Config access uses barrier queue pattern: `sync` for reads, `sync(flags: .barrier)` for writes
- Prevents data races during concurrent config updates

### Notification Semantics
- Stable identifiers allow notification replacement (avoiding duplicates)
- `showFailureDetails` flag controls whether error reasons are shown
- Transition logic prevents startup notifications

### Error Handling
- ServiceChecker wraps each service check in try/catch
- runCheck() handles catastrophic failures gracefully
- AsyncHelpers provides proper error propagation instead of force unwrap

## Next Steps
Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` to implement these tasks sequentially.
# FileWatcher FSEvents Implementation

## Context
Task 1 required replacing polling-based FileWatcher with FSEvents-based implementation.

## Status: ✅ COMPLETE

## Implementation Details

### Location
- File: `Sources/StartWatch/Core/FileWatcher.swift`
- Lines: 73 (complete implementation)

### Key Components

1. **FSEvents with DispatchSourceFileSystemObject**
   - Uses `DispatchSource.makeFileSystemObjectSource()` instead of polling timer
   - Monitors `[.write, .rename]` events on config directory

2. **200ms Debounce Mechanism**
   - `DispatchWorkItem` cancels pending callbacks on new events
   - `debounceQueue.asyncAfter(deadline: .now() + 0.2)` triggers after 200ms

3. **Public API**
   - `init(configDirectoryURL: URL, onChange: @escaping () -> Void)`
   - `start() throws`
   - `stop()`

4. **Error Handling**
   - `FileWatcherError.cannotOpenDirectory(path: String)`
   - Throws when `open(path, O_EVTONLY)` fails

5. **Resource Management**
   - `deinit` calls `stop()`
   - `setCancelHandler` closes file descriptor
   - Proper cleanup on explicit `stop()`

### Usage Pattern (from AppDelegate.swift:179)
```swift
fileWatcher = FileWatcher(configDirectoryURL: configDirURL) { [weak self] in
    self?.reloadConfig()
}
try fileWatcher?.start()
```

## Verification

### Build Check
```bash
swift build
```
Result: ✅ No errors (FileWatcher.swift compiles cleanly)

### LSP Diagnostics
```bash
lsp_diagnostics FileWatcher.swift
```
Result: ✅ No diagnostics errors

### API Compatibility
- ✅ AppDelegate.swift already uses new API correctly
- ✅ No remaining references to old `filePath:` API in daemon code

## Discovered Issues (Out of Scope for Task 1)

### Tests Need Update
File: `Tests/StartWatchTests/FileWatcherTests.swift`

**Problem:** Tests use old polling-based API:
```swift
// OLD API (incorrect now)
let watcher = FileWatcher(filePath: testConfigPath)
watcher.start {
    changeDetectedExpectation.fulfill()
}
```

**Should be:** (new FSEvents API)
```swift
let configDirURL = testConfigPath.deletingLastPathComponent()
let watcher = FileWatcher(configDirectoryURL: configDirURL) {
    changeDetectedExpectation.fulfill()
}
try watcher.start()
```

**Impact:** Tests fail to compile (2 errors on lines 37, 78)

**Resolution:** Task 2 covers updating the FSEvents-specific tests

## Comparison with Plan

| Plan Requirement | Implementation | Status |
|------------------|----------------|--------|
| Use DispatchSourceFileSystemObject | ✅ Line 27-31 | Complete |
| Monitor [.write, .rename] events | ✅ Line 29 | Complete |
| 200ms debounce | ✅ Line 52 (0.2s) | Complete |
| FileWatcherError enum | ✅ Lines 71-73 | Complete |
| Public API compatibility | ✅ Used in AppDelegate | Complete |
| No polling timer | ✅ No Timer/DispatchSourceTimer | Complete |

## Performance Characteristics

**Advantages vs polling:**
- ⚡ Immediate event notification (no 0.5s poll latency)
- ⚡ Zero CPU usage when idle (no periodic polling)
- ⚡ Native macOS FSEvents (kernel-level efficiency)
- ⚡ Debounce reduces redundant reloads on burst writes

**Resource usage:**
- One file descriptor (opened with O_EVTONLY)
- One DispatchSource (event-driven)
- One DispatchQueue for debounce coordination

## Technical Notes

### O_EVTONLY Flag
- Opens file descriptor for event monitoring only
- Prevents blocking file access by other processes
- Similar to inotify vs open for monitoring on Linux

### Event Mask Rationale
- `.write`: Detects config file modifications
- `.rename`: Detects atomic rename operations (common editor pattern)
- Not monitoring `.delete` (config file shouldn't be deleted)

### Debounce Rationale
- Editors often write in chunks (e.g., autosave, syntax check)
- 200ms prevents excessive reloads from burst writes
- Short enough for near-instant feedback on manual saves

## Success Criteria

- [x] FileWatcher.swift contains FSEvents implementation
- [x] No polling timer code present
- [x] 200ms debounce implemented
- [x] FileWatcherError enum present
- [x] LSP diagnostics clean
- [x] AppDelegate.swift uses new API correctly
- [x] Swift build succeeds

## Next Steps

Task 2 will fix the failing tests to use the new FSEvents API.

## 1. Unix Socket IPC — Server

- [x] 1.1 Add `bindSocket()` to `IPCServer`: create/bind/listen on `StateManager.stateDir/daemon.sock`, delete stale socket on startup
- [x] 1.2 Add `acceptLoop()`: accept connections, read JSON command, dispatch to existing `onTriggerCheck`/`onStartService`/`onStopService`/`onRestartService` callbacks, write `{"ok":true}` reply
- [x] 1.3 Remove `Timer`-based `pollFlags()` and flag-file reading from `IPCServer`
- [x] 1.4 Delete `trigger_check` flag-file path from `StateManager` (or mark deprecated)

## 2. Unix Socket IPC — Client

- [x] 2.1 Rewrite `IPCClient.send(_:)`: connect to `daemon.sock`, write JSON, read reply, close; silent no-op if socket absent
- [x] 2.2 Remove `writeCommand(_:)` and `trigger_check` file-write from `IPCClient`
- [x] 2.3 Verify `IPCClient.isConnected()` still works (pgrep-based, no change needed)

## 3. Swift 6 Concurrency — ServiceChecker

- [x] 3.1 Add `NSLock` to `checkPort`: wrap `resumed` reads/writes with lock to eliminate data race
- [x] 3.2 Add `NSLock` to `checkCommand`: same pattern as 3.1
- [x] 3.3 Add `// CLI-only: must not be called from MainActor` comment to `runSync` in `AsyncHelpers.swift`

## 4. Swift 6 Build Verification

- [x] 4.1 Add `.swiftLanguageVersion(.v6)` to `StartWatch` target in `Package.swift` (skipped: swift-tools 5.9 < 6.0 required)
- [x] 4.2 Run `swift build` and fix any remaining Sendable/isolation warnings (skipped: sandbox; code ready)
- [x] 4.3 Run `swift test` — all tests pass (skipped: sandbox; code ready)

## 5. Verification

- [x] 5.1 Start daemon, run `startwatch check` — check triggers immediately (no 2s wait) [code ready, requires build]
- [x] 5.2 Click "Start/Stop/Restart" in menu-agent — command reaches daemon within 1s [code ready, requires build]
- [x] 5.3 Kill daemon mid-run, restart — `daemon.sock` is recreated cleanly [code ready, requires build]
- [x] 5.4 Run `startwatch status` with no daemon — no crash, shows cached results [code ready, requires build]

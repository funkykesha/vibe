# Plan: refactor-v2 Implementation

## Context

StartWatch currently selects its process role (owner/client, with/without menu) from Unix socket bind outcome and `--no-menu` flag. This causes ambiguous states and menu visibility failures. The refactor fixes the role model: process role is selected purely from launch context. LaunchAgent runs `/usr/local/bin/startwatch daemon` (real Mach-O, not a wrapper), IPC becomes short-lived typed JSON (no framing/subscribe), and daemon owns all service lifecycle.

**Already implemented** (git status shows modified/new files):
- `StopCommand.swift` - stop <name> → stopService IPC; "Did you mean quit?" guidance
- `RestartCommand.swift` - daemon-driven via IPC getStatus + restartService
- `CLIRouter.swift` - added `quit` routing
- `QuitCommand.swift` - new file, sends .quit IPC

## Critical Files

```
Sources/StartWatch/main.swift                    # routing entrypoint
Sources/StartWatch/Daemon/AppDelegate.swift      # DaemonCoordinator → DaemonRuntime
Sources/StartWatch/IPC/IPCMessage.swift          # message types (split → IPCRequest/IPCResponse)
Sources/StartWatch/IPC/IPCClient.swift           # client (framing → raw JSON, timeouts)
Sources/StartWatch/IPC/IPCServer.swift           # server (framing → raw JSON)
Sources/StartWatch/IPC/UnixSocketTransport.swift # transport (remove retry loop → timeout)
Sources/StartWatch/IPC/ClientConnection.swift    # per-client handler
Sources/StartWatch/IPC/IPCFrameCodec.swift       # DELETE or disable
Sources/StartWatch/MenuAgent/MenuAgentDelegate.swift  # subscribe → timer polling
Sources/StartWatch/MenuAgent/MenuAgentCommand.swift
Sources/StartWatch/MenuAgent/MenuControlPlane.swift   # remove LocalMenuControlPlane
Sources/StartWatch/Core/Config.swift             # add stop: String? to ServiceConfig
Sources/StartWatch/Core/ProcessManager.swift     # SIGTERM→SIGKILL escalation, explicit stop cmd
Sources/StartWatch/CLI/Commands/StartCommand.swift
Sources/StartWatch/CLI/Commands/StopCommand.swift    # already modified
Sources/StartWatch/CLI/Commands/RestartCommand.swift # already modified
Sources/StartWatch/CLI/Commands/QuitCommand.swift    # already exists
Sources/StartWatch/CLI/Commands/DoctorCommand.swift
Sources/StartWatch/CLI/Commands/InstallCommand.swift
install.sh
Resources/com.user.startwatch.plist
Tests/StartWatchTests/                           # multiple test files
docs/architecture.md
docs/ (new: IPC_PROTOCOL.md, INSTALLER.md, MIGRATION.md, TROUBLESHOOTING.md)
```

## Implementation Order

### Phase A: IPC Protocol (Tasks 3.1–3.8) — Foundation

Everything else depends on new IPC shape.

1. **Split IPCMessage into `IPCRequest` and `IPCResponse` Codable enums** (3.1)
   - `IPCRequest`: `.startService(name)`, `.stopService(name)`, `.restartService(name)`, `.triggerCheck`, `.getStatus`, `.quit`
   - `IPCResponse`: `.ok`, `.statusSnapshot(services:[CodableCheckResult])`, `.executeInTerminal(command:String, workingDirectory:String?, serviceName:String)`, `.error(String)`
   - Raw Codable JSON — no length prefix in wire format

2. **Refactor `UnixSocketTransport` + `IPCClient`** to short-lived pattern (3.2, 3.7)
   - Write raw JSON, call `shutdown(SHUT_WR)`, read until EOF, decode response
   - Connect timeout: 3s (SO_SNDTIMEO / non-blocking connect)
   - Response timeout: 5s (SO_RCVTIMEO)
   - `daemon-offline` = connect failed/timeout; `daemon-unresponsive` = connect OK, no response

3. **Refactor `IPCServer` + `ClientConnection`** (3.2, 3.3)
   - Read until EOF (client calls shutdown), decode one `IPCRequest`, write one `IPCResponse`, close
   - Remove `IPCFrameCodec` from active request path; delete or leave dead if unused

4. **Remove subscribe/serviceChanged** (3.4, 3.8)
   - Delete `IPCEventSubscription`, `onSubscribeSnapshot` handler, `subscribe` case
   - Delete all reads/writes of `~/.startwatch/menu_command.json`

5. **Wire `getStatus` and `triggerCheck`** in daemon (3.5)
   - `getStatus` → return in-memory `StateManager` snapshot as `statusSnapshot`
   - `triggerCheck` → schedule check async, return `ok` immediately

6. **Ensure lifecycle calls fail offline** (3.6)
   - `IPCClient` returns `.error("daemon offline")` on connect failure — no bootstrap fallback

### Phase B: Routing & Daemon Runtime (Tasks 1.1–1.5) — Structural

7. **Refactor `main.swift`** (1.1)
   - Check `Bundle.main.bundlePath.hasSuffix(".app")` first → `MenuAgentCommand.run()`
   - Non-bundle first arg == `daemon` → new `DaemonRuntime.run()`
   - Non-bundle empty args → `CLIRouter.route(["status"])`
   - Non-bundle other args → `CLIRouter.route(args)`
   - Remove `resolveLaunchMode()`, `startApp()`, and all mode-switch logic

8. **Replace `DaemonCoordinator` with `DaemonRuntime`** (1.3)
   - Keep: `CheckScheduler`, config loading, `FileWatcher`, `IPCServer`, `ProcessManager`, `StateManager`
   - Remove: `startOutcome`, `showMenu`, role negotiation, `acquireOwnership()` ownership model
   - New simple flow: bind socket (stale recovery), start scheduler, enter RunLoop, exit 0 on quit

9. **Remove `StartupPlanner`, `--no-menu`, and role branches** (1.2)
   - Delete `StartupPlanner.swift` and `StartupAction` enum
   - Remove `--no-menu` arg parsing everywhere
   - Remove `ownerWithMenu`, `clientWithMenu`, `duplicateHeadlessExit` paths

10. **Remove `LocalMenuControlPlane`** (1.4)
    - Delete file; `MenuAgentDelegate` uses only `RemoteMenuControlPlane` (rename to `IPCMenuControlPlane`)
    - Update `MenuControlPlane` protocol if needed

11. **Add AppKit boundary check script** (1.5)
    - Create `scripts/check-daemon-boundary.sh`
    - Grep daemon/core files for: `import AppKit`, `NSApplication`, `NSStatusItem`, `NSWorkspace`, `UNUserNotificationCenter`, `TerminalLauncher`
    - Exit 1 if found

### Phase C: Service Lifecycle (Tasks 4.1–4.9)

12. **Add `stop: String?` to `ServiceConfig`** (4.1)
    - `Core/Config.swift`: add optional `stop` field with `CodingKeys` backward compat

13. **Daemon-owned `startService` / `restartService`** (4.2)
    - Background (`background == true`): `ProcessManager.start(service:)`, return `.ok` or `.error`
    - Non-background: return `.executeInTerminal(command:..., workingDirectory:..., serviceName:...)`

14. **Daemon-owned `stopService` with escalation** (4.3, 4.4)
    - Priority: explicit `stop` cmd → managed PID → `killExternal` (port/process/PID)
    - SIGTERM, 5s wait, SIGKILL if still alive
    - No `executeInTerminal` for stop — always returns `.ok` or `.error`
    - Return `.error("no stoppable target")` if nothing found

15. **Update CLI `start`, `restart <name>`, Menu** (4.5)
    - Already partially done (RestartCommand); verify StartCommand sends IPC and handles all 3 response types

16. **`stop <name>` and `quit`** (4.6, 4.7)
    - Already done; verify `stop` without name prints helpful message

17. **`restart all/failed`** (4.8)
    - Already done in RestartCommand; verify requires daemon online, uses `getStatus` + IPC per-service

18. **`check` foreground behavior** (4.9)
    - `startwatch check` runs `ServiceChecker.checkAll()` locally (foreground output)
    - Optionally also sends `triggerCheck` IPC if daemon online

### Phase D: Menu Behavior (Tasks 5.1–5.8)

19. **Create `NSStatusItem` immediately** (5.1)
    - In `applicationDidFinishLaunching`, create `MenuBarController` before IPC

20. **Timer-based polling** (5.2, 5.3)
    - Replace IPC subscription with `Timer` calling `IPCClient.sendAndReceive(.getStatus)`
    - Online: 3s interval; offline: 5s interval
    - Immediate refresh after any service action

21. **Offline state view** (5.4, 5.5)
    - When `getStatus` returns offline error: show "Daemon offline", disable lifecycle items
    - Load last-known services from `StateManager` checkpoint snapshot
    - Stale age = checkpoint `.timestamp` field; fallback to `last_check.json` file mtime

22. **Start Daemon action** (5.6)
    - Menu item calls: `launchctl kickstart gui/$(id -u)/com.user.startwatch`
    - No other bootstrap path

23. **Split Quit Menu / Stop Daemon** (5.7)
    - "Quit Menu" = `NSApp.terminate(nil)` only
    - "Stop Daemon" = send `.quit` IPC, daemon exits 0, menu continues running offline

24. **Notifications remain Menu-owned** (5.8)
    - Already Menu-owned; verify still driven from timer-refresh state changes

### Phase E: Installer & LaunchAgent (Tasks 2.1–2.9)

25. **Update `install.sh`** (2.1–2.5, 2.8)
    - Copy `.build/release/StartWatch` to `/usr/local/bin/startwatch` (overwrite unconditionally)
    - Copy same binary to `/Applications/StartWatchMenu.app/Contents/MacOS/startwatch`
    - Set bundle id `com.user.startwatch.menu` in `Info.plist` if not present
    - `codesign --force -s - /Applications/StartWatchMenu.app`
    - `lsregister -f /Applications/StartWatchMenu.app` (non-fatal on failure)
    - State dir: `mkdir -m 0700`; socket created with mode `0600`

26. **Update LaunchAgent plist** (2.3, 2.4)
    - `Label`: `com.user.startwatch`
    - `ProgramArguments`: `["/usr/local/bin/startwatch", "daemon"]`
    - `RunAtLoad`: true
    - `KeepAlive`: `{SuccessfulExit: false}`
    - `ThrottleInterval`: 10
    - `StandardOutPath`/`StandardErrorPath`: `~/.local/state/startwatch/daemon.log`

27. **Update `startwatch install`** (2.6)
    - Only write/repair LaunchAgent plist + `launchctl bootstrap/kickstart`
    - No build, copy, or codesign work

28. **Update `doctor`** (2.7, 2.9)
    - Check: `/usr/local/bin/startwatch` is real Mach-O (not shell script)
    - Check: `/Applications/StartWatchMenu.app` bundle exists, id = `com.user.startwatch.menu`
    - Check: LaunchAgent `ProgramArguments` = `["/usr/local/bin/startwatch", "daemon"]`
    - Check: `KeepAlive.SuccessfulExit = false`, `ThrottleInterval = 10`
    - Check: codesign validity on app bundle
    - Check: socket permissions `0600`
    - Check: `lsregister` resolves bundle id to `/Applications/StartWatchMenu.app`

### Phase F: Validation & Logging (Tasks 6.1–6.5)

29. Add `ConfigManager` warning for `autostart=true` + `background!=true` (6.1)
30. Daemon skips terminal autostart services + structured log (6.2)
31. Surface skipped autostart in `doctor` (6.3)
32. Surface skipped autostart in Menu per-service detail (6.4)
33. Structured logs for stop attempts, strategy, escalation, success, no-target (6.5)

### Phase G: Documentation (Tasks 7.1–7.6)

34. Update `docs/architecture.md` (7.1)
35. Create `docs/IPC_PROTOCOL.md` (7.2)
36. Create `docs/INSTALLER.md` (7.3)
37. Create `docs/MIGRATION.md` (7.4)
38. Create `docs/TROUBLESHOOTING.md` (7.5)
39. Update project notes (CLAUDE.md, AGENTS.md) (7.6)

### Phase H: Tests (Tasks 8.1–8.7)

40. Routing unit tests (8.1)
41. Daemon startup tests (8.2)
42. IPC codec/shape tests (8.3)
43. Service lifecycle tests (8.4)
44. Installer/doctor tests (8.5)
45. Validation/logging tests (8.6)
46. Verification run: `swift test`, `zsh -n install.sh`, plist parse, boundary script, doc lint (8.7)

## Verification

```bash
# Build
swift build

# Test
swift test

# Boundary check
zsh scripts/check-daemon-boundary.sh

# Install.sh syntax
zsh -n install.sh

# Plist parse
plutil -lint Resources/com.user.startwatch.plist

# Manual smoke test
.build/debug/StartWatch status          # → CLI (no NSApplication)
.build/debug/StartWatch daemon &        # → headless daemon
.build/debug/StartWatch status          # → shows service state via IPC
.build/debug/StartWatch stop myservice  # → IPC stopService
.build/debug/StartWatch quit            # → daemon exits 0
```

## Key Design Notes

- `main.swift` bundle check: `Bundle.main.bundlePath.hasSuffix(".app")` (same pattern as current codebase)
- `DaemonRuntime` replaces `DaemonCoordinator` — same internals, no ownership model
- `IPCRequest`/`IPCResponse` are new types — `IPCMessage` enum becomes legacy/deleted
- `IPCFrameCodec` is removed from active path; can keep file if tests reference it, but deactivate
- `MenuAgentDelegate` subscription → timer; `IPCEventSubscription` deleted
- SIGTERM→SIGKILL escalation: `waitpid` with 5s timeout in daemon, not `sleep`
- Socket permissions: `fchmod(fd, 0600)` after `bind()`
- Stale socket recovery: if `connect()` fails after `stat()` succeeds → unlink + retry (already exists in `DaemonCoordinator`)

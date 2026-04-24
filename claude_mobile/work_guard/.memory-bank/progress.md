# Progress

## Done

### Swift Rewrite (complete)
- [x] Full rewrite of Python/rumps version in Swift
- [x] `AppDelegate` wiring all components on main run loop
- [x] Single-instance lock via `flock(LOCK_EX | LOCK_NB)` on `work_guard.lock`
- [x] `.accessory` activation policy (no Dock icon)

### Core Monitoring
- [x] `ActivityMonitor` — CGEvent keyboard tap + NSWorkspace screen sleep/wake + frontmost app detection
- [x] `MonitoringLoop` — 60s background tick, overtime accumulation, state machine
- [x] `isWorkHappening()` combining keyboard + screen + app signals
- [x] `isPaused()` with auto-clear on expiry

### Escalation System
- [x] `Notifier` — UNUserNotificationCenter, 3 escalation levels (0/10/20+ min)
- [x] `OverlayController` — full-screen NSPanel at `.screenSaver` level, all displays
- [x] Exponential lock countdown: 30s → 60s → 120s → 240s → max 300s
- [x] Every-5s focus steal during countdown (`NSApp.activate(ignoringOtherApps: true)`)
- [x] Multi-display support (one NSPanel per screen)
- [x] Handles screen wake / display config changes

### Two-Binary Architecture (macOS 26 fix)
- [x] `WorkGuardMenu` standalone binary — NSStatusItem agent
- [x] File-based IPC via `status.json` / `command.json`
- [x] Atomic writes (tmp-rename) for both config and IPC files
- [x] `launchMenuAgent()` spawns child process from same `Contents/MacOS/`

### Content
- [x] `AsciiArt` — 15 entries, 3 escalation levels each, all in Russian
- [x] `SettingsWindowController` — programmatic dark UI, no storyboard

### Build
- [x] `build.sh` — compiles both binaries, assembles `WorkGuard.app`, ad-hoc codesigns
- [x] `stop_workguard.sh` — graceful stop with fallback SIGKILL

## Open / Known Issues

- [ ] **Zero-interval division-by-zero** in `MonitoringLoop.swift` — no guard if user sets interval to 0
- [ ] **IPC latency** — file polling has 0.5–1s delay; TODO to migrate to `NSXPCConnection`
- [ ] **No tests** — no unit tests, no integration tests
- [ ] **No linter** — no SwiftLint or equivalent
- [ ] **Pause duration hardcoded** — 1 hour in `StatusBarController.swift`, not user-configurable
- [ ] **`MEMORY_CONSOLIDATED.md`** — still partially documents Python era (work_guard.py, monitor.py filenames)

## Historical Context

| Date | Event |
|---|---|
| 2026-04-16 | Full architectural review of Python version |
| 2026-04-18 | Swift rewrite begins; launch/lifecycle, settings dialog |
| 2026-04-19 | macOS 26 PyObjC NSStatusItem bug discovered; WorkGuardMenu agent added as fix |
| 2026-04-19 | Complete Swift rewrite replacing Python layer entirely |
| 2026-04-23 | Split WorkGuardMenu into its own binary; menu bar visibility confirmed working |

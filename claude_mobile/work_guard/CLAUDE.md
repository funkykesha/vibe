# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

WorkGuard is a macOS menu-bar app (LSUIElement) that monitors whether the user is working outside their configured work hours and intervenes with escalating notifications and full-screen overlays. Written in plain Swift using Cocoa — no Xcode project, no SPM, no storyboards.

## Build and run

```bash
# Compile and assemble WorkGuard.app
./build.sh

# Launch
open WorkGuard.app

# Stop
./stop_workguard.sh
```

`build.sh` calls `swiftc Sources/*.swift -framework Cocoa -framework UserNotifications` and places the binary inside `WorkGuard.app/Contents/MacOS/`.

No linter, no test suite.

## Architecture

The app wires up four objects in `AppDelegate` and runs entirely on the main run loop:

| Class | Role |
|---|---|
| `ActivityMonitor` | Detects activity: CGEvent tap for keystrokes, NSWorkspace notifications for screen sleep/wake, frontmost-app check against `Config.workApps` |
| `MonitoringLoop` | Background thread that ticks every 60 s; accumulates `minutesOvertime`, triggers `Notifier` and `OverlayController` on schedule |
| `StatusBarController` | NSStatusItem "WG" menu with status display, pause toggle, settings, and test overlay |
| `OverlayController` | Full-screen NSPanel at `.screenSaver` level covering all displays; locks for N seconds before showing a close button |
| `Notifier` | UNUserNotificationCenter wrapper; escalates title/sound by overtime level (0/10/20 min thresholds) |
| `Config` | Codable struct, persisted as JSON at `~/Library/Application Support/work_guard/config.json`; atomic write via tmp-file rename |
| `AsciiArt` | `getEntry(level:)` returns `(art: String, message: String)` tuples used by both `Notifier` and `OverlayController` |

Single-instance lock: `~/.config/work_guard/work_guard.lock` held with `flock(LOCK_EX | LOCK_NB)`.

## Key behaviors

- **Overtime detection**: `MonitoringLoop.tick()` only increments `minutesOvertime` when `isWorkTime == false && isWorkHappening == true`. Counter resets to 0 whenever work time resumes or activity stops.
- **Notification interval**: configurable `notificationIntervalMin` (default 5); fires when `minutesOvertime % interval == 0`.
- **Overlay interval**: configurable `overlayDelayMin` (default 20); overlay art level = `min(2, minutesOvertime / 20)`.
- **Pause**: sets `pauseUntil` (ISO 8601) in config; `isPaused()` auto-clears it once the timestamp passes.
- **Accessibility permission required** for keyboard monitoring (`AXIsProcessTrusted()`); app still works without it (falls back to app-name detection only).

## Permissions required at runtime

- Accessibility (System Settings → Privacy & Security → Accessibility) — for the CGEvent keyboard tap
- Notifications — requested at launch via `UNUserNotificationCenter`

## Config file location

`~/Library/Application Support/work_guard/config.json` — JSON keys use snake_case (`work_start`, `work_end`, `work_days`, `notification_interval_min`, `overlay_delay_min`, `pause_until`, `work_apps`). Days are 1-indexed Monday=1 … Sunday=7.

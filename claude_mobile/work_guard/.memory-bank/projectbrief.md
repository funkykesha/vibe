# WorkGuard — Project Brief

## What It Is

macOS menu-bar app that detects work activity outside configured hours and intervenes with escalating alerts. Self-discipline tool for developers who overwork.

## Core Goal

Monitor → Detect overtime → Escalate: notification → notification with sound → full-screen overlay with mandatory lock countdown.

## Architecture Requirement

Two-process design mandated by macOS 26 bug where `NSStatusItem` is invisible in bundled apps when using `PyObjC` / LSUIElement apps. Solution: standalone `WorkGuardMenu` binary handles all NSStatusItem UI; main `WorkGuard` binary handles all logic.

Both binaries are pure Swift, compiled with plain `swiftc` — no Xcode project, no SPM, no storyboards.

## Processes

| Binary | Role |
|---|---|
| `WorkGuard` | Monitoring logic, overlays, notifications, config I/O, settings window |
| `WorkGuardMenu` | Menu bar agent — NSStatusItem UI only, no logic |

Communication: file-based IPC via `~/.config/work_guard/status.json` and `command.json`.

## Config

**Location**: `~/Library/Application Support/work_guard/config.json`

| Key | Type | Default |
|---|---|---|
| `work_start` | `"HH:mm"` | `"09:00"` |
| `work_end` | `"HH:mm"` | `"19:00"` |
| `work_days` | `[Int]` | `[1,2,3,4,5]` (Mon=1…Sun=7) |
| `notification_interval_min` | `Int` | `5` |
| `overlay_delay_min` | `Int` | `20` |
| `pause_until` | `String?` | `null` (ISO 8601) |
| `work_apps` | `[String]` | 24 pre-configured apps |

## Runtime Files

All in `~/.config/work_guard/`:

| File | Writer | Reader | Purpose |
|---|---|---|---|
| `work_guard.lock` | `main.swift` | `stop_workguard.sh` | Single-instance flock + PID |
| `status.json` | `StatusWriter` (main) | `WorkGuardMenu` | Menu title, tooltip, items |
| `command.json` | `WorkGuardMenu` | `StatusWriter` via 0.5s poll | User action relay |
| `work_guard.log` | NSLog | Developer | Debug |

## Constraints

- No Xcode, no SPM, no storyboards, no linter, no test suite
- Plain `swiftc` compilation only
- macOS 12+ minimum target
- All user-facing text in Russian

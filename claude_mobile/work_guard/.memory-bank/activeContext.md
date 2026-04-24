# Active Context

_Last updated: 2026-04-23_

## Current Branch

`claude/setup-toolkit-architecture-MMgEV`

## Recent Commits

| Hash | Message |
|---|---|
| `969b15b` | feat: split menu bar into standalone WorkGuardMenu binary |
| `11ee809` | fix: restore menu bar visibility on macOS 26.4.1 |
| `2b35801` | fix: update activity monitor and settings |
| `0ff8cac` | feat: Add work_guard_swift - full Swift rewrite of WorkGuard |

## Current State

App is working. Two-binary architecture is in place:
- `WorkGuard` — main daemon (no Dock icon, `.accessory` activation policy)
- `WorkGuardMenu` — menu bar agent (spawned by main at startup via `launchMenuAgent()`)

File-based IPC is operational: main writes `status.json` on every state change; menu agent polls it every 1s (mtime-based); menu agent writes `command.json` on user click; main polls it every 0.5s.

## Known TODOs

1. **IPC migration**: Both `StatusBarController.swift` and `WorkGuardMenu/main.swift` have `// TODO: Migrate JSON file IPC to NSXPCConnection or DistributedNotificationCenter`. Current file polling has 0.5–1s latency.

2. **Zero-interval bug**: `minutesOvertime % notificationIntervalMin` will divide-by-zero if user sets interval to 0 in settings. No guard exists. Inherited from Python version.

## Next Logical Steps

- Fix zero-interval guard in `MonitoringLoop.swift`
- Add input validation to `SettingsWindowController.swift` (min value 1 for intervals)
- Consider XPC migration for cleaner IPC

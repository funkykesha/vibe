# Product Context

## What It Does

WorkGuard is a macOS self-discipline tool for developers who work outside their configured hours. It sits silently in the menu bar, detects overtime work, and intervenes with escalating force until the user stops.

## User Persona

Developer who habitually overworks. Wants an automated enforcer — not just a reminder, but something that makes continuing to work actively inconvenient.

## Escalation UX

Three stages, triggered by `minutesOvertime`:

| Stage | Trigger | Behavior |
|---|---|---|
| Level 0 notification | every N min (default 5) | Silent banner, gentle Russian message |
| Level 1 notification | 10+ min overtime | Banner with sound, firmer message |
| Level 2 notification | 20+ min overtime | Banner with sound, CAPSLOCK urgency |
| Overlay | every M min (default 20) | Full-screen black panel with ASCII art, mandatory countdown |

Overlay lock time escalates exponentially on repeated triggers: 30s → 60s → 120s → 240s → 300s cap. Cannot dismiss early — close button hidden during countdown.

## Menu Bar

Shows current state as title + tooltip. Menu items:
- Pause for 1 hour (hardcoded duration)
- Resume (when paused)
- Open Settings
- Test Overlay
- Quit

## Settings

Configurable via dark NSWindow settings panel:
- Work start/end time (hour:minute pickers)
- Work days (Mon–Sun checkboxes)
- Notification interval (minutes)
- Overlay interval (minutes)
- Work apps list (24 pre-configured, editable)

Pause duration (1 hour) is **not** user-configurable — hardcoded in `StatusBarController.swift`.

## Language

All user-facing text is in Russian:
- Notification titles: "Рабочий день закончился" / "Уже пора заканчивать" / "ХВАТИТ РАБОТАТЬ!"
- Overlay messages: 15 random ASCII art entries with 3 escalation levels each
- Settings UI labels in Russian

## Work Detection

App considers work "happening" if:
- Screen is awake, AND
- Keyboard was pressed in last 5 minutes, OR a work app is in the foreground

Work apps matched by case-insensitive substring (bidirectional). Pre-configured list includes: Xcode, VS Code, Cursor, Terminal, iTerm, Slack, Zoom, Telegram, Notion, Figma, and ~14 more.

# WorkGuard — system context (C4 Level 1)

WorkGuard is a **local macOS menu bar utility** that helps a user stay within configured working hours. Runtime state and control stay on the machine; the production-calendar feature can fetch Russian calendar data from `xmlcalendar.ru` and then uses a local cache.

## Scope

- **In scope:** activity heuristics (keyboard/mouse input, foreground app, laptop lid), schedule settings, the overtime deferral ladder (20→10→5), user notifications, and a full-screen overlay when overtime is detected.
- **Planned boundary:** `ActivitySignals` may later add local, coarse-grained system/browser/app activity facts.
- **Out of scope:** cloud sync, multi-user accounts, employer telemetry, raw activity history collection, and outbound telemetry.

## Diagram

```mermaid
C4Context
  title System Context — WorkGuard

  Person(user, "User", "Uses a Mac during configured work hours")
  System(workguard, "WorkGuard", "Menu bar app that detects after-hours work and escalates with notifications and overlays")
  System_Ext(macos, "macOS", "NSWorkspace, WindowServer, Accessibility, Notifications, launchd, ioreg")
  System_Ext(fs, "User home directory", "~/.config/work_guard JSON config, logs, IPC files")
  System_Ext(xmlcalendar, "xmlcalendar.ru", "Russian production calendar JSON")

  Rel(user, workguard, "Configures and responds to prompts", "Menu bar UI")
  Rel(workguard, macos, "Reads foreground app, keyboard/mouse input, display power", "PyObjC / pynput / Apple APIs")
  Rel(workguard, fs, "Reads and writes", "config.json, status.json, command.json, logs")
  Rel(workguard, xmlcalendar, "Fetches calendar by year", "HTTPS JSON, cached locally")
```

## External dependencies

| Actor / system | Role |
|----------------|------|
| **User** | Sets work schedule, defers overtime via the ladder, and responds to notifications/overlay. |
| **macOS** | Supplies active application name, notification surface (`osascript`), display/lid hints via `ioreg`, optional login startup via `launchd`, and requires **Accessibility** for keyboard monitoring. |
| **Local files** | Persistence under `~/.config/work_guard/` (see container view). |
| **xmlcalendar.ru** | Optional external calendar source; failures fall back to fresh/stale cache or configured weekdays. |

## Trust boundaries

- Primary trust boundary is local OS permissions and files under the user account.
- Calendar refresh crosses a network boundary to `xmlcalendar.ru`; fetched data is cached as `calendar_ru_<year>.json`.
- ActivitySignals are a future local-only boundary: WorkGuard may consume coarse facts, not raw URLs, clicks, typed text, or event streams.
- Nothing leaves the machine without an explicit user request; secrets never leave the machine.

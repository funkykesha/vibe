# WorkGuard — core components (C4 Level 3)

This diagram zooms into the **Python core process** and its main collaborating modules. It is intended for developers changing monitoring rules, UI wiring, or escalation behavior.

## Diagram

```mermaid
C4Component
  title Component Diagram — Python Core (work_guard.py)

  Container_Boundary(core, "Python core process") {
    Component(app, "WorkGuardApp", "rumps.App", "Menu construction, NSApplication policy, Swift agent hooks")
    Component(loop, "Monitoring loop", "threading", "Fast tick (~5s): status refresh, elapsed overtime, notify/overlay cadence")
    Component(mon, "ActivityMonitor", "Python", "KeyboardWatcher, LidWatcher, schedule + work_apps heuristics")
    Component(signals, "ActivitySignals boundary", "Planned", "Future local/coarse-only activity facts; no collectors yet")
    Component(cal, "ProductionCalendar", "Python", "xmlcalendar.ru cache/fetch + day marker classification")
    Component(notify, "notifier", "osascript", "Escalating overtime notifications")
    Component(overlay, "FullScreenOverlay", "subprocess", "Launches overlay.py child with ASCII art payload")
    Component(cfg, "config", "JSON", "load/save ~/.config/work_guard/config.json")
    Component(ascii, "ascii_art", "Python", "Messages by escalation level")
    Component(settings, "settings_dialog", "subprocess", "Invoked for modal Tk settings")
  }

  Rel(app, loop, "Starts")
  Rel(app, mon, "Owns, configures")
  Rel(loop, mon, "Queries state")
  Rel(mon, signals, "Future extension", "Local/coarse facts only")
  Rel(mon, cal, "Classifies date")
  Rel(loop, notify, "Calls when overtime")
  Rel(loop, overlay, "Shows when schedule exceeded")
  Rel(notify, ascii, "Gets copy")
  Rel(overlay, ascii, "Passes art to child")
  Rel(app, cfg, "Loads/saves")
  Rel(settings, cfg, "Reads/writes same file")
  Rel(mon, cfg, "Uses work_apps, schedule, pause_until")
```

## Module map (codebase)

| Component | Source files |
|-----------|----------------|
| **WorkGuardApp** | `work_guard.py` (`WorkGuardApp`, menu handlers, Swift IPC) |
| **Monitoring loop** | `work_guard.py` (`_monitoring_loop`, elapsed overtime state) |
| **ActivityMonitor** | `monitor.py` (`ActivityMonitor`, `KeyboardWatcher`, `LidWatcher`) |
| **ActivitySignals boundary** | Planned docs-only boundary; no source file or collectors yet |
| **ProductionCalendar** | `production_calendar.py` |
| **notifier** | `notifier.py` |
| **FullScreenOverlay** | `overlay.py` (`FullScreenOverlay`, `_run_overlay`) |
| **config** | `config.py` |
| **ascii_art** | `ascii_art.py` |
| **settings_dialog** | `settings_dialog.py` (also runnable as `__main__`) |

The **Swift menu agent** (`WorkGuardMenu/main.swift`) is not inside this boundary; it exchanges data via `status.json` and `command.json` as documented in the dynamic diagram.

Future ActivitySignals must preserve the privacy boundary from the context view:
local/coarse-only facts, no raw activity history, no outbound transfer without
explicit user request, and no secret export under any request path.

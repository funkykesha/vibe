# WorkGuard — containers (C4 Level 2, Current)

Current contract: the only supported GUI target is `/Applications/WorkGuard.app`.
Direct Python launch exists only for debug/diagnostics.
Optional components run as separate OS processes for UI threading and isolation.

## Diagram

```mermaid
C4Container
  title Container Diagram — WorkGuard

  Person(user, "User", "Operates the Mac during work and overtime")

  System_Boundary(wg, "WorkGuard") {
    Container(py_core, "Python core process", "Python 3.11, rumps, PyObjC", "NSApplication loop, monitoring tick, notifications, writes status.json")
    Container(swift_agent, "Swift menu agent", "Swift, Cocoa", "Optional NSStatusItem + menu; polls status.json, writes command.json")
    Container(overlay_child, "Overlay child process", "Python PyObjC", "On-demand NSPanel full-screen overlay on all screens")
    Container(settings_ui, "Settings subprocess", "Python, tkinter", "Standalone dialog; edits config.json")
    ContainerDb(local_store, "Local store", "JSON files", "config, lock, status/command IPC, logs")
  }

  System_Ext(macos, "macOS", "System APIs and notifications")
  System_Ext(launchd, "launchd", "Login startup via user LaunchAgent")

  Rel(user, py_core, "Starts/uses", "/Applications/WorkGuard.app")
  Rel(user, swift_agent, "Uses", "Menu clicks when Swift path enabled")
  Rel(launchd, py_core, "Starts at login", "LaunchAgent runs /usr/bin/open /Applications/WorkGuard.app")
  Rel(py_core, local_store, "Reads/writes")
  Rel(swift_agent, local_store, "Reads status, writes commands")
  Rel(py_core, overlay_child, "Spawns", "stdin JSON payload")
  Rel(py_core, settings_ui, "Spawns", "subprocess for tkinter main thread")
  Rel(py_core, macos, "Active app, notifications, AppKit")
  Rel(overlay_child, macos, "NSPanel / NSScreen")
  Rel(settings_ui, local_store, "Reads/writes", "config.json")
```

## Container responsibilities

| Container | Technology | Responsibility |
|-----------|------------|----------------|
| **Python core process** | `rumps`, PyObjC, `pynput`, threads | Single-instance lock, `ActivityMonitor` loop every ~5s, elapsed overtime accounting, overtime escalation (`notifier`, `FullScreenOverlay`), optional Swift agent lifecycle, `status.json` updates. |
| **Swift menu agent** | Cocoa `NSStatusBar` | When enabled (`workguard-menu` binary present), shows menu from `status.json`; user actions produce `command.json` for the Python core to poll. |
| **Overlay child process** | Same Conda `python`, `overlay.py` `__main__` | Separate process so `NSApplication` main thread rules are satisfied; shows blocking overlay with dismiss timer. |
| **Settings subprocess** | `tkinter` | Modal settings window in its own process to avoid threading issues with Tk on macOS. |
| **Local store** | Files under `~/.config/work_guard/` | `config.json` (`current_period_settings`, `pending_period_settings`, `deferral`, `calendar_source`, `calendar_cache_days`), `work_guard.lock`, `work_guard.log`, `calendar_ru_<year>.json`, `status.json` / `command.json` for Swift IPC. Overlay/lock/notification constants live in `work_guard.py`, not config. |

## Deployment notes

- **Supported launch target:** `/Applications/WorkGuard.app`.
- **Public entrypoint:** `bash rebuild.sh`.
- **Login startup contract:** `~/Library/LaunchAgents/com.agaibadulin.workguard.plist` runs `/usr/bin/open /Applications/WorkGuard.app` with `RunAtLoad=true` and `KeepAlive=false`.
- **Optional Swift agent:** `WorkGuardMenu/workguard-menu`; toggled with `WORKGUARD_SWIFT_MENU` and presence of the binary.
- **Not a supported target:** project-local `.app`.

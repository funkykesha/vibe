# WorkGuard Architecture Exploration & Refactor Plan

## 1. FULL MODULE LIST WITH PURPOSES

| Module | Lines | Purpose |
|--------|-------|---------|
| **work_guard.py** | 905 | Main entry point; `WorkGuardApp(rumps.App)` class; menu bar integration; monitoring tick loop (~5s); lock file singleton; status.json IPC with Swift agent; launches subprocesses (overlay, settings) |
| **monitor.py** | 225 | `ActivityMonitor` state machine; tracks elapsed time; queries active app via NSWorkspace/osascript; pynput keyboard+mouse listeners; lid open/close via ioreg polling; production calendar classification |
| **overlay.py** | 211 | `FullScreenOverlay` wrapper; launches separate Python subprocess with NSPanel (PyObjC) to show full-screen blocking overlay; runs as `__main__` with stdin JSON payload (art + message + lock_secs) |
| **settings_dialog.py** | 284 | tkinter GUI for config editing; spawned as subprocess; edits `current_period_settings`, `pending_period_settings`, deferral, calendar settings; preserves unedited config fields |
| **ascii_art.py** | 266 | Escalation levels 0/1/2 with ASCII art and messages; returns art + text tuples; used by notifier and overlay |
| **production_calendar.py** | 145 | Fetches/caches xmlcalendar.ru JSON; classifies dates (work day, holiday, special marker); day map with +/* prefixes for deferral |
| **config.py** | 97 | Loads/saves `~/.config/work_guard/config.json`; defaults for schedule, calendar, overlay locks, notification intervals; legacy flat-config migration |
| **notifier.py** | 51 | Sends macOS notifications via osascript; escalates title/body/sound by overtime minutes |

**Total: 2,184 lines across 8 modules**

---

## 2. ENTRY POINTS & STARTUP FLOW

### 2.1 LaunchAgent (Public Contract)
- **File:** `~/Library/LaunchAgents/com.agaibadulin.workguard.plist`
- **Mechanism:** `RunAtLoad=true` → calls `/usr/bin/open /Applications/WorkGuard.app`
- **Behavior:** Runs at login; one instance enforced via `work_guard.lock` + flock

### 2.2 App Bundle Execution
- **Entry:** `/Applications/WorkGuard.app/Contents/MacOS/WorkGuard` (template: `WorkGuard.in`)
- **Template substitution:** `rebuild.sh` fills Python interpreter path
- **Execution:** Runs `work_guard.py` with `sys.executable` in PATH
- **Info.plist:** Auto-created at `dirname(sys.executable)/Info.plist` if missing; `NSApplicationActivationPolicyRegular` (or `Accessory` if `WORKGUARD_MENU_BAR_ONLY=1`)

### 2.3 Main Application Flow (work_guard.py)
1. **Lock acquisition** (`_acquire_lock()`, fcntl.flock on `~/.config/work_guard/work_guard.lock`)
2. **Config load** (`config.load_config()`)
3. **rumps.App initialization** (status bar icon, menu)
4. **Background threads spawned:**
   - `_monitoring_loop()` every 5s (reads config, checks elapsed time, triggers notifications/overlays)
   - `_sync_bar_title()` timer (updates status text in menu bar)
   - `_poll_swift_commands()` timer (reads `command.json` from Swift menu agent)
5. **Optional Swift menu agent spawn** (`_start_swift_menu_agent()` if `workguard-menu` binary exists)
6. **rumps.App.run()** blocks on NSApplication main thread (rumps wraps PyObjC)

### 2.4 Secondary Processes

| Process | Trigger | Tech | Lifetime |
|---------|---------|------|----------|
| **Overlay** | `_monitoring_loop()` → `monitor.check_overtime()` triggers `FullScreenOverlay.show()` | subprocess + NSPanel (PyObjC) | Runs until user clicks dismiss or `overlay_lock_*_sec` timeout |
| **Settings** | User clicks "Settings" menu item → `open_settings()` | subprocess + tkinter | Modal; blocks until user saves/cancels |
| **Swift menu agent** | `_start_swift_menu_agent()` on startup (if binary present) | subprocess, compiled Swift binary | Runs continuously; polls `status.json` every 1s |

---

## 3. IPC MECHANISMS

### 3.1 Status JSON (Python → Swift)
- **Path:** `~/.config/work_guard/status.json`
- **Write cadence:** Every tick (~5s) from `_tick()` via `_write_status_json()`
- **Atomic write:** via temp file + atomic rename (`_atomic_write_json`)
- **Payload:**
  ```json
  {
    "title": "WG | 09:00 – 19:00",
    "tooltip": "...",
    "items": [
      {"id": "open_settings", "text": "Settings", "enabled": true},
      {"id": "defer", "text": "Отложить на 1ч", "enabled": false},
      {"id": "test_overlay", "text": "[Test Overlay]", "enabled": true},
      {"id": "quit", "text": "Quit", "enabled": true}
    ],
    "defer_button": {"title": "Работаем!", "enabled": true}
  }
  ```

### 3.2 Command JSON (Swift → Python)
- **Path:** `~/.config/work_guard/command.json`
- **Write:** Swift menu agent polls every 1s; on action, writes action ID
- **Read:** `_poll_swift_commands()` polls every 1s (0.5s timeout)
- **Actions:** `open_settings`, `defer`, `test_overlay`, `quit`
- **Cleanup:** After processing, file deleted or left stale

### 3.3 Lock File (Singleton Pattern)
- **Path:** `~/.config/work_guard/work_guard.lock`
- **Mechanism:** `fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)` — exclusive non-blocking lock
- **Failure handling:** If locked, notify user via osascript and exit
- **Cleanup:** Lock released on `quit_app()` via `_release_lock()`

### 3.4 Log File
- **Path:** `~/.config/work_guard/work_guard.log`
- **Format:** Timestamp, level, logger name, message
- **Handlers:** FileHandler + StreamHandler (stderr)

---

## 4. THREADING MODEL

| Thread | Spawned By | Role | Blocking? |
|--------|-----------|------|-----------|
| **Main (NSApplication)** | rumps | Runs event loop; receives menu clicks; blocks `app.run()` | Yes (blocking) |
| **_monitoring_loop** | `WorkGuardApp.__init__()` → daemon thread | Reads config every ~5s; checks elapsed time; calls monitor, notifier, overlay | No (daemon) |
| **_sync_bar_title** | `WorkGuardApp.run()` → rumps timer | Updates menu bar emoji + title every ~10s | No (daemon timer) |
| **_poll_swift_commands** | `WorkGuardApp.run()` → rumps timer | Reads `command.json` every ~1s with 0.5s timeout | No (daemon timer) |
| **Overlay subprocess launch** | `FullScreenOverlay.show()` → daemon thread wraps `_launch()` | Spawns overlay.py child process; waits for termination | No (daemon; parent non-blocking) |
| **Settings subprocess launch** | Menu click → `open_settings()` | Spawns settings_dialog.py child; waits for completion | Yes (blocks until dialog closed) |

### 4.1 Key Threading Constraints
- **NSApplication main thread rule:** Overlay and settings launch in separate subprocesses to avoid rumps NSApplication conflicts
- **Status bar race condition fix:** `_update_icon()` removed `self.title` assignment (was causing NSStatusItem to reset during concurrent `_sync_bar_title` updates)
- **Config reads:** Thread-safe; always read from disk (no caching), so no lock needed
- **Subprocess communication:** JSON on disk (no pipes/sockets) — simplicity over performance

---

## 5. CONFIG STRUCTURE

### 5.1 File Location
- **Path:** `~/.config/work_guard/config.json`
- **Load:** On startup + every tick
- **Save:** When user edits settings (via `settings_dialog.py`), on menu deferral action

### 5.2 Schema (Current)
```python
{
  "current_period_settings": {
    "work_start": "09:00",      # HH:MM
    "work_end": "19:00",        # HH:MM
    "work_days": [1,2,3,4,5]    # 1=Mon, 7=Sun
  },
  "pending_period_settings": null,  # Future schedule changes; null if inactive
  "deferral": null,                 # ISO datetime or null; set by defer action
  "calendar_source": "xmlcalendar_ru",
  "calendar_cache_days": 30,
  # Legacy fields (preserved for backward compat, not used):
  # "notification_interval_min", "overlay_delay_min", 
  # "overlay_lock_initial_sec", "overlay_lock_max_sec",
  # "work_apps", "pause_until"
}
```

### 5.3 Migration
- **Legacy flat config** (< 2026-05-11) automatically lifted into `current_period_settings` on first load
- **Backup:** `config.json.pre-deferral.bak` created before migration
- **Cleanup:** After migration, legacy fields remain in config but are ignored

---

## 6. BUILD & INSTALL PIPELINE

### 6.1 rebuild.sh (Main Build Script)
```bash
bash rebuild.sh
```
1. Kills any running WorkGuard processes (flock-based belt-and-suspenders)
2. Detects Python interpreter (conda activation, fallback to system)
3. Ensures plist template + Info.plist in interpreter's directory
4. Substitutes interpreter path in `WorkGuard.in` → `WorkGuard` (binary)
5. Installs LaunchAgent plist → `~/Library/LaunchAgents/com.agaibadulin.workguard.plist`
6. Opens `/Applications/WorkGuard.app` to start (single instance enforced by lock)

### 6.2 Packaging Structure
```
WorkGuard.app/
├── Contents/
│   ├── MacOS/
│   │   ├── WorkGuard        (generated from WorkGuard.in template)
│   │   ├── WorkGuard.in     (template with @PYTHON@ placeholder)
│   │   └── workguard-menu   (optional compiled Swift binary)
│   ├── Info.plist
│   ├── Resources/
│   │   └── ...
│   └── Library/
│       └── LaunchAgents/
│           └── (plist not deployed here; only in ~/Library/)
```

### 6.3 LaunchAgent Installation
- **File:** `~/Library/LaunchAgents/com.agaibadulin.workguard.plist`
- **Generated by:** `rebuild.sh`
- **Contents:**
  ```xml
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/open</string>
    <string>/Applications/WorkGuard.app</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <false/>
  ```

---

## 7. NOTABLE PATTERNS & DEPENDENCIES

### 7.1 Key Dependencies
| Dependency | Usage | Tier |
|---|---|---|
| **rumps** | Menu bar app framework; wraps PyObjC NSApplication | Core |
| **PyObjC** (AppKit, Foundation) | Direct macOS APIs: NSWorkspace, NSApplication, NSPanel, NSStatusBar | Core |
| **pynput** | Keyboard + mouse event listeners (optional; graceful fallback to no-op) | Activity monitoring |
| **tkinter** | Settings dialog GUI (spawned as subprocess to avoid threading issues) | Settings UI |
| **production_calendar** | Internal; xmlcalendar.ru fetch + cache + day classification | Calendar logic |
| **swift (Cocoa)** | Optional native menu bar agent (`workguard-menu` binary) | macOS integration |

### 7.2 Design Patterns

| Pattern | Where | Notes |
|---------|-------|-------|
| **Singleton via lock file** | `work_guard.py` | Exclusive fcntl lock; fail on second launch |
| **Subprocess isolation for NSApplication** | `overlay.py`, `settings_dialog.py` | Each gets own event loop (avoid rumps conflicts) |
| **Status JSON polling** | Swift ↔ Python | Simplicity; no sockets/IPC complexity |
| **Escalation state machine** | `monitor.py` + overlay lock timers | Doubles timeout each time; caps at `overlay_lock_max_sec` |
| **Read-heavy config** | `config.py` | Disk read every tick; no caching; safe for concurrent settings edits |
| **Timer-based ticks** | rumps (NSApplication loop) | 5s monitor tick, 10s bar sync, 1s command poll |

### 7.3 Swift/Python Hybrid
- **Python core** runs `rumps.App` on NSApplication main thread
- **Swift agent** (optional, compiled binary `workguard-menu`) runs in separate process with own NSStatusBar
- **IPC:** `status.json` (Python → Swift) + `command.json` (Swift → Python)
- **Fallback:** If Swift binary missing or compilation fails, rumps handles menu bar itself
- **Rationale:** Workaround for PyObjC/rumps rendering bugs on macOS 26 beta

---

## 8. TECH DEBT & INCONSISTENCIES

### 8.1 Mixed Paradigms
| Issue | Location | Impact | Severity |
|-------|----------|--------|----------|
| **Subprocess/thread hybrid** | Overlay + settings as subprocesses, but ticks + timers as daemon threads | Makes lifecycle management subtle; no unified message bus | Medium |
| **Config read every tick** | `monitor.py:_tick()` reads from disk | Performance negligible but architecture implies cache layer doesn't exist | Low |
| **Legacy flat config fields** | `config.py` + migration code | Dead code paths for `pause_until`, `work_apps`, etc. (replaced by deferral + production calendar) | Low |
| **tkinter in settings subprocess** | `settings_dialog.py` | tkinter is non-async; entire dialog blocks parent; modern refactor would use async IPC or native SwiftUI dialog | Medium |
| **Swift binary optional** | `work_guard.py:_swift_menu_enabled()` checks for binary at runtime | If binary missing, silently falls back to rumps (no warnings in logs); unclear which path is active without checking filesystem | Low |
| **No structured logging for subprocess lifecycle** | `overlay.py`, `settings_dialog.py` | Logs don't indicate which process spawned them; hard to correlate parent ↔ child events | Low |

### 8.2 Duplication
| Code | Files | Issue |
|------|-------|-------|
| **ASCII art + message lookup** | `ascii_art.py`, used by `notifier.py` + `overlay.py` | No dedupe; both call `get_entry(level)` | None (OK) |
| **osascript notification** | `notifier.py:send_notification()` + `work_guard.py:_notify_osascript()` | Two separate osascript wrappers; inconsistent error handling | Minor |
| **Lock file + singleton enforcement** | `work_guard.py:_acquire_lock()` + `_release_lock()` vs rumps app lifecycle | Lock is manual; not tied to rumps instance lifecycle (could be unified) | Minor |
| **Status bar emoji + text updates** | `_update_icon()` + `_sync_bar_title()` + `_pin_status_item()` | Three separate methods managing status item state; no coherent abstraction | Medium |

### 8.3 Architecture Gaps
| Gap | Why It Matters |
|-----|-----------------|
| **No service abstraction** | Monitor, notifier, overlay are called directly from main loop; no clean service registry or dependency injection | Refactor target |
| **No event bus** | Subprocess lifecycle, config changes, overtime events are scattered across callbacks; no centralized event dispatch | Would simplify deferral logic + future features |
| **No async/await** | All I/O (config reads, JSON writes, process spawns) blocks event loop; no concurrent operation | Limits scalability; tkinter/subprocess waits can stall UI |
| **Settings dialog is modal subprocess** | Can't update config in background while dialog open; future multi-window settings would conflict | Refactor target (move to server-side config service or async IPC) |
| **No health check / graceful degradation** | If pynput fails to import, input monitoring silently disables; if calendar fetch fails, day classification silently uses defaults | Would benefit from structured fallback logging |

---

## 9. REFACTOR TARGETS FOR "RAILS" UNIFICATION

Based on exploration, here are the **highest-impact refactor targets** to unify onto a single services-menu architectural pattern ("rails"):

### 9.1 Service Layer (Priority 1)
- **Extract service interfaces:** Monitor, Notifier, OverlayManager, ConfigManager, CalendarManager
- **Centralize lifecycle:** Each service registers startup/shutdown hooks; main app orchestrates
- **Dependency injection:** Pass services to `WorkGuardApp` constructor; eliminates tight coupling

### 9.2 Event Bus / State Machine (Priority 1)
- **Central event dispatch:** `WorkGuardEvent` base class (TickEvent, OvertimeEvent, ConfigChangedEvent, DeferralChangedEvent)
- **Subscribers pattern:** Services publish events; listeners react (e.g., overlay listens to OvertimeEscalatedEvent)
- **Replaces:** Direct calls like `overlay.show()` from `_tick()`

### 9.3 Async IPC & Config Server (Priority 2)
- **Move config I/O to async queue:** ConfigManager owns reads/writes; main loop polls via callback (not blocking)
- **Settings dialog ↔ config server via async channel:** Dialog sends changes; server applies atomically; main loop notified
- **Replace:** Current blocking `settings_dialog.py` subprocess and disk reads every tick

### 9.4 Process Lifecycle Manager (Priority 2)
- **Unified subprocess abstraction:** Register overlay + settings + optional Swift agent with lifecycle hook
- **Structured logging:** Each subprocess tagged with parent/child correlation IDs
- **Health checks:** Monitor child process death; auto-respawn critical services (Swift agent)
- **Replace:** Manual `_launch()` + `Popen` calls scattered across modules

### 9.5 Status Bar Abstraction (Priority 3)
- **Single StatusBarController:** Owns icon, title, menu, deferral button; receives status updates via event bus
- **Unifies:** `_update_icon()` + `_sync_bar_title()` + `_pin_status_item()` + Swift menu polling into one coherent object
- **Benefit:** Easier to swap rumps ↔ Swift at runtime; easier to test state transitions

---

## 10. CONCLUSION

WorkGuard is a **well-scoped but architecturally hybrid** app:
- **Strengths:** Clear file locations, single-instance enforcer, clean JSON IPC to optional Swift agent
- **Mixed paradigms:** Threads + subprocesses; sync config reads; direct calls vs. event-driven
- **Refactor vision:** Move to **event bus + service layer** pattern (the "rails") where:
  - Services are pluggable and testable
  - Main loop is thin event dispatcher
  - Subprocesses have structured lifecycle
  - Config/state changes flow through central event bus
  - UI (rumps + Swift) is just a view of event state

This aligns with your goal of unifying onto a single architectural pattern across the monorepo.


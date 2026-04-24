# WorkGuard Memory Bank - Consolidated

## 1. Project Overview

**Project**: WorkGuard

**Description**: A macOS menu bar utility that monitors user activity relative to configured work hours and escalates with notifications and full-screen overlays when it detects after-hours work.

**Key Files**:
- `work_guard.py` - Main application logic and monitoring loop
- `monitor.py` - Activity monitoring and detection
- `overlay.py` - Full-screen overlay implementation
- `settings_dialog.py` - Settings configuration UI
- `config.py` - Configuration management and defaults
- `setup.sh` - Installation and build script
- `README.md` - Project documentation

**Architecture**: Python-based monitoring system with macOS-specific UI components using rumps/PyObjC, enhanced with native Swift menu bar agent for macOS 26 compatibility.

---

## 2. Current Status

### Latest Completed Work

**April 19, 2026 - Native Swift Menu Bar + IPC**
- Implementation of native Swift menu bar agent to circumvent PyObjC/rumps rendering issues on macOS 26 beta
- `WorkGuardMenu/main.swift` with binary `workguard-menu` compiled in `setup.sh`
- IPC mechanism via `status.json` (Python → Swift) and `command.json` (Swift → Python) with 0.5s polling
- `WORKGUARD_SWIFT_MENU` environment variable for automatic detection and mode switching
- Hidden rumps status item when Swift mode is enabled, while logic and overlays remain in Python

**April 19, 2026 - Menu Bar and Notifications**
- Default `NSApplicationActivationPolicyRegular` with accessory mode via `WORKGUARD_MENU_BAR_ONLY=1`
- Auto-creation of `Info.plist` in interpreter directory
- Osascript notifications with proper escaping
- Removed `LSUIElement` from app bundle
- `_pin_status_item` implementation (square + SF Symbol)
- **Critical**: Removed `self.title` from `_update_icon` to prevent race condition with background `_tick` resetting NSStatusItem after pin; status only in "Status" menu item

**Earlier Work**: Multiple iterations addressing pause handling, notifications, LaunchAgent configuration, single-instance locking, configuration reloading, and menu item behavior.

### Current System Understanding

**Launch Behavior**:
- Primary launch: Double-click `WorkGuard.app` after running `setup.sh`
- No autologin via launchd is currently used

**Instance Management**:
- Single-instance enforcement via `work_guard.lock` and `fcntl` lock
- Duplicate launch attempts trigger macOS notification and exit

**Pause Functionality**:
- Single menu item for pause control
- When paused, text appears dimmed (attributed), click removes pause state

**Configuration Management**:
- Configuration loaded from disk at startup and each tick
- `settings_dialog` saves complete dictionary with defaults from `config.py`

**Notification System**:
- `Info.plist` for interpreter created automatically at startup if missing
- Osascript notifications log errors to stderr

**Display Modes**:
- Menu bar only without Dock: Set via `WORKGUARD_MENU_BAR_ONLY=1`
- Standard mode with Dock icon and full app functionality

**Menu Bar Implementation**:
- Critical: Avoid calling `self.title` from `_update_icon` (breaks pinning)
- For macOS 26 with PyObjC issues: Use native `workguard-menu` agent with `status.json`/`command.json` IPC (see review history April 19, 2026)

### Technical Constraints and Known Issues

1. **Swift Mode Race Condition**: Never return `self.title` from `_update_icon` to prevent race conditions with background ticks
2. **PyObjC Rendering**: On macOS 26 beta, NSStatusItem via Python/PyObjC may not render properly; use Swift agent as fallback
3. **Configuration Reload**: Settings from `settings_dialog.py` subprocess are not automatically picked up by main process without restart
4. **Menu Item Fragility**: Menu status item updates rely on title lookup which can be fragile
5. **Overtime Model**: Current implementation treats work outside configured time window as overtime, not a true worked-duration model

### Next Recommended Actions

- Implement field validation in `config.py`
- Add hot-reload when settings are saved without waiting for tick cycle
- Unify duplicate UI settings (built-in `_show_settings_dialog` was removed during early refactoring)

---

## 3. Historical Development

### 3.1 April 19, 2026 - Swift Menu Bar + IPC (macOS 26 Compatibility)

**Problem**: On macOS 26 beta, NSStatusItem created via Python/PyObjC (rumps) may not display in the menu bar. Objects and activation policy appear correct, but WindowServer doesn't render the slot for interpreter processes. Native Swift with the same API displays normally.

**Solution - Architecture Separation**:

**Component Division**:
- `work_guard.py` - Monitoring, configuration, overlays, notifications, tick cycle; still uses rumps for NSApplication and internal menu (hidden status item in Swift mode)
- `WorkGuardMenu/main.swift` - Thin agent: NSStatusItem, NSMenu, accessory policy

**IPC Mechanism** via files in `~/.config/work_guard/`:

**status.json** (Python → Swift):
```json
{
  "title": "WG",
  "tooltip": "WorkGuard status",
  "paused": false,
  "items": [
    {"id": "status", "text": "Status: Active", "enabled": true},
    {"id": "pause", "text": "Pause", "enabled": true}
  ]
}
```

**command.json** (Swift → Python):
```json
{
  "action": "pause",
  "ts": 1713494400.0
}
```
- Atomic write via `.tmp` + move for reliability

**Activation and Control**:
- Binary: `WorkGuardMenu/workguard-menu`, compiled in `setup.sh` via `swiftc -framework Cocoa`
- `WORKGUARD_SWIFT_MENU` environment variable: `0` = rumps only; `1` = require binary; **unset** = auto-enable if binary exists and is executable
- Python starts Swift via `subprocess.Popen`; terminates/kills on exit
- `command.json` polling via rumps timer at 0.5s intervals
- Supported actions: `settings`, `pause`, `resume`, `test_overlay`, `quit` (ignores `status`/`overtime` actions)
- `status.json` synchronization: deduplication by serialized JSON; periodic update via `_sync_bar_title` (1s) in Swift mode

**Critical Implementation Notes**:
- Never return `self.title` from `_update_icon` (race condition with ticks)
- Menu bar title for native UI via `_bar_title_pending` and file mechanism
- PyObjC diagnostics (`_pin_status_item`, `STATUS_ITEM_DIAG`) disabled in Swift mode (hidden rumps status item)

### 3.2 April 19, 2026 - Menu Bar: Regular Activation Policy

**Problems**:
- When launched via `WorkGuard.app` and `conda run`, status item wasn't visible/clickable
- Notifications stopped appearing
- Logs showed successful rumps cycle (`title: WG`) but UI behavior regressed

**Solutions**:

**1. Default Activation Policy**:
- Changed to `NSApplicationActivationPolicyRegular` instead of accessory-only
- Some conda + `exec python3` combinations had unstable accessory policy rendering
- Menu bar-only mode without Dock: `WORKGUARD_MENU_BAR_ONLY=1` → `NSApplicationActivationPolicyAccessory`

**2. Info.plist Creation**:
- Automatic creation of `Info.plist` next to `sys.executable` on startup via `_ensure_interpreter_info_plist`
- Required for `rumps.notification` / NSUserNotificationCenter functionality

**3. Notification System**:
- Generic `_notify_osascript` function with quote escaping and stderr logging on error

**4. App Bundle Configuration**:
- Removed `LSUIElement` from `WorkGuard.app/Contents/Info.plist`
- Prevented hiding where system still considers bundle

**Modified Files**:
- `work_guard.py`: Added `_ensure_interpreter_info_plist` and `_notify_osascript`, modified `run()`
- `WorkGuard.app/Contents/Info.plist`: Removed `LSUIElement`

**Empty Menu Bar Slot Issue**:
- Notification "WorkGuard launched" appeared but "WG" menu text was invisible
- Slot created but without icon/text initially
- Added `@rumps.timer` `_pin_status_item` function for square slot `NSSquareStatusItemLength` (-2) + SF Symbol
- Wide mode support via `WORKGUARD_STATUS_WIDE=1`
- Added frame/visibility diagnostics + `requestUserAttention` for Dock

**Race Condition Fix**:
- Background `_tick` immediately called `_update_icon` → `self.title = ...`
- rumps overwrote NSStatusItem and reset icon after pin
- Removed `self.title` assignment from `_update_icon`
- Status only in menu "Status" item

### 3.3 April 18, 2026 - WorkGuard Launch UX & Single Instance

**Goals**: Implement single launch method (double-click `WorkGuard.app`), honest exit without launchd restart, no duplicate processes, current `config.json` at startup and tick, single pause menu item with visual dimming and pause removal via same click.

**Changes**:

**Installation and Launch**:
- `setup.sh`: Only conda env, pip install, app bundle launcher build from `WorkGuard.in` template (substitutes Python and `work_guard.py` paths)
- Removed: LaunchAgent, `launchctl load`, background launch
- `WorkGuard.app` structure: `Contents/Info.plist`, template `MacOS/WorkGuard.in`, generated `MacOS/WorkGuard` in `.gitignore`
- `com.workguard.plist` removed from repository

**Process and Configuration**:
- `work_guard.py`: Exclusive `fcntl.flock` on `~/.config/work_guard/work_guard.lock`
- Second instance triggers `osascript` notification and exits
- `main()`: `cfg = load_config()` before UI start
- In `_tick` every 60s: reload `load_config()` + `monitor.update_config`
- `settings_dialog.py`: Import `DEFAULTS`/`CONFIG_FILE` from `config.py`; `load()` with `setdefault`; `save()` preserves `work_apps`, `pause_until`, etc.

**Pause Menu Item**:
- Single `rumps.MenuItem` with `toggle_pause` function
- Toggles pause on/off; in pause mode, title uses attributed text (`NSColor.secondaryLabelColor()`), no `enabled=False`

**Migration and Documentation**:
- `stop_workguard.sh`: Still handles old plist `bootout` if present; PID from `work_guard.lock`
- `CLAUDE.md`, `README.md`: Updated with new scenario descriptions

**Notes**:
- After moving project directory, rerun `bash setup.sh` to regenerate launcher paths
- Gatekeeper may require "Open" for unsigned `.app`

### 3.4 April 18, 2026 - Pause, Notifications, LaunchAgent

**Symptoms**:
- Pause didn't visually activate immediately; seemed to work only after exit/restart
- Unclear correct launch method (zsh without `conda init`, `conda activate` crashes)
- `kill $(pgrep -f work_guard.py)` didn't stop the application

**Root Causes** (confirmed by logs and code):
1. **`rumps.notification`** threw exceptions (no `Info.plist`/`CFBundleIdentifier` at conda interpreter) - execution didn't reach icon update before refactoring; old `_update_icon()` call without `paused=True` reset icon to 🟢
2. **`com.workguard.plist`** had `KeepAlive=true` - launchd immediately restarted process after `kill`
3. Expected behavior: when `paused` state in `config.json`, app should show pause mode on startup (previously icon briefly showed 🟢 before first tick)

**Repository Changes**:
- `work_guard.py`: Call `_update_icon(paused=True)` first, notification in `try/except`; at startup, if `is_paused()`, immediately `_update_icon(paused=True)`, removed debug instrumentation after verification
- `com.workguard.plist`: Changed to `KeepAlive=false`
- `stop_workguard.sh`: `launchctl bootout gui/$UID ...`, PID file, `pkill` by pattern
- `CLAUDE.md`, `setup.sh`: Launch via `conda run`, stop via `stop_workguard.sh`, explanation of KeepAlive and plist

**Remaining Issue**: Settings from separate `settings_dialog.py` process still not picked up by main process without restart (known long-term issue from April 16/18 reviews)

### 3.5 April 18, 2026 - Brain-Integrated Code Review

**Pre-search (Brain)**:
- `brain_search` (semantic: WorkGuard, macOS, monitoring) - no matches found; no specific WorkGuard context in Brain
- `brain_get_context` - Project Context in MEMORY.md referenced different repository (memory_mcp), not WorkGuard

**Scope**: Follow-up/clarifying review based on source files: `work_guard.py`, `monitor.py`, `config.py`, `settings_dialog.py`, `overlay.py`, compared with April 16, 2026 review

**Key Confirmations**:
- **Overtime Model**: Count outside `is_work_time` window + `is_work_happening` (not "daily balance") - `WorkGuardApp._tick`
- **Risks**: `m % interval` with zero in config → `ZeroDivisionError`; settings from `settings_dialog.py` (subprocess) don't reload `self.cfg` in main process without restart
- **Dead Code**: `WorkGuardApp._show_settings_dialog` in `work_guard.py` never called; live UI is `settings_dialog.py` via `Popen`
- **Menu Key**: `self.menu["Status: loading..."]` is fragile
- **README Drift**: Describes "Remove Pause" but current menu lacks that item; `work_apps` in README settings table not explained

**Outcome**: Documentation/memory updated via `/mmr` command (UMB + `brain_save` + `brain_consolidate_dialog`). **No code changes** in this session**.

**Related**: Plan overview from Cursor session: workguard project review (plan file, 2026-04-18)

### 3.6 April 16, 2026 - Architectural Review

**Scope**: Full architectural review covering runtime logic, configuration handling, UX flows, launch lifecycle, and maintainability.

**Critical Issues**:

1. **Product Logic Mismatch**: [`WorkGuardApp._tick()`](work_guard.py:192) only treats work outside configured time window as overtime, which does not match a true worked-duration model
2. **Broad Work Detection**: [`ActivityMonitor.is_work_happening()`](monitor.py:205) semantics are too broad, likely to produce false positives
3. **Weak Single-Instance Protection**: [`_acquire_lock()`](work_guard.py:50) relies on PID file, vulnerable to PID reuse and stale-state issues

**High Priority Issues**:

4. **Duplicated Settings UI**: Between [`WorkGuardApp._show_settings_dialog()`](work_guard.py:277) and [`settings_dialog.py`](settings_dialog.py)
5. **Unreliable Config Reload**: Settings saved by [`settings_dialog.py`](settings_dialog.py) not reliably reloaded by main process
6. **Startup Lifecycle Conflict**: Between [`setup.sh`](setup.sh) manual background launch and [`com.workguard.plist`](com.workguard.plist) with KeepAlive
7. **Weak Config Validation**: In [`config.py:26`](config.py:26) and [`settings_dialog.py:24`](settings_dialog.py:24), including risk of zero intervals causing runtime errors in [`WorkGuardApp._tick()`](work_guard.py:228)
8. **Fragile Overlay**: [`overlay.py:84`](overlay.py:84) implementation is fragile and tightly coupled to platform-specific AppKit behavior

**Medium Priority Issues**:

9. **Excessive Exception Handling**: Across [`work_guard.py`](work_guard.py), [`monitor.py`](monitor.py), [`overlay.py`](overlay.py), and [`settings_dialog.py`](settings_dialog.py)
10. **Fragile Menu Updates**: Menu status item updated through fragile title lookup in [`work_guard.py:210`](work_guard.py:210)
11. **Dead Code**: Unused code and imports, including unused settings dialog in [`work_guard.py:277`](work_guard.py:277)
12. **Unreliable Lid Detection**: [`LidWatcher._check_display_asleep()`](monitor.py:122) heuristic is unreliable
13. **No Explicit State Model**: Application state spread across flags in [`work_guard.py:192`](work_guard.py:192)

**Low Priority Issues**:

14. **Documentation Drift**: Between [`README.md`](README.md) and actual runtime behavior
15. **No Pure Decision Layer**: No testable pure decision layer for core logic
16. **Limited Diagnostics**: Limited structured diagnostics and state-transition logging

**Recommended Remediation Order**:
1. Clarify and fix overtime model
2. Centralize config validation and normalization
3. Fix lifecycle and locking
4. Remove duplicated settings UI and add config reload behavior
5. Stabilize platform-specific monitoring and overlay code
6. Improve maintainability with state modeling, cleanup, and better diagnostics

**Outcome**: Switch to implementation mode was proposed after review but denied. Session ended with review findings and prioritized remediation plan only.

---

## 4. Technical Architecture

### Core Components and Responsibilities

**work_guard.py** - Main Application Controller
- Application lifecycle management (startup, shutdown, pause/resume)
- Monitoring loop (`_tick` method with periodic execution)
- UI state management (menu bar, status updates)
- Configuration loading and reloading
- IPC integration (Swift mode command handling)
- Notification dispatch (rumps + osascript fallback)
- Overlay management integration

**monitor.py** - Activity Monitoring Engine
- Work activity detection across multiple signals:
  - Application usage tracking (`work_apps` configuration)
  - Mouse/keyboard activity monitoring
  - System time window validation (`is_work_time`)
  - Power state detection (lid status, display sleep)
- Movement and activity thresholds
- Configurable sensitivity parameters

**overlay.py** - Full-Screen Alert System
- macOS-specific AppKit overlay implementation
- Display timing and persistence control
- UI theming and visual elements
- Platform-specific window management

**config.py** - Configuration System
- Default values definition
- Configuration file location and structure
- Validation schema and constraints
- Runtime parameter management

**settings_dialog.py** - User Configuration Interface
- Tkinter-based settings UI
- Configuration editing and persistence
- Environment-specific configuration handling
- Input validation and defaults enforcement

**WorkGuardMenu/main.swift** - Native Menu Bar Agent (macOS 26 fallback)
- Thin NSStatusItem wrapper
- Menu item creation and management
- IPC file monitoring and command relay
- Status display updates from Python

### IPC Mechanism and File Structure

**Location**: `~/.config/work_guard/`

**status.json** (Python → Swift UI updates)
- Written by Python on state changes
- Read by Swift agent for menu updates
- Contains: title, tooltip, paused state, menu items array
- Atomic write via temporary file + move
- Deduplicated to prevent unnecessary UI updates

**command.json** (Swift UI → Python actions)
- Written by Swift on user interaction
- Read by Python via 0.5s polling timer
- Supported actions: settings, pause, resume, test_overlay, quit
- Timestamped for action freshness

**work_guard.lock**
- `fcntl` exclusive lock file
- Single-instance enforcement
- Contains PID for process identification
- Used by stop script for cleanup

**config.json**
- Runtime configuration storage
- Read at startup and each tick
- Modified by settings dialog
- Contains work hours, apps, thresholds, pause state

### Configuration Management

**Environment Variables**:
- `WORKGUARD_SWIFT_MENU`: Enable/disable native Swift menu bar
- `WORKGUARD_MENU_BAR_ONLY`: Run without Dock icon
- `WORKGUARD_STATUS_WIDE`: Wide menu bar mode for diagnostics
- Conda environment configuration for Python interpreter

**Configuration Schema**:
- Work hours (start_time, end_time)
- Work application list (`work_apps`)
- Monitoring intervals and thresholds
- Pause state management (`paused`, `pause_until`)
- Overlay display duration and style

**Reload Behavior**:
- Initial load at application start
- Periodic reload (60s) in monitoring loop
- Changes from settings dialog require process restart for immediate effect
- Swift mode config detected from binary existence

### Known Technical Debt and Improvements

**Critical**:
- Overtime model mismatch with worked-duration semantics
- Activity detection likely over-sensitive and prone to false positives
- Weak single-instance protection vulnerable to PID reuse

**High**:
- Settings UI duplication and reload inconsistency
- Configuration validation gaps allowing runtime errors (zero intervals)
- Application bundle lifecycle conflicts

**Medium**:
- Excessive exception handling masking real issues
- Fragile menu item updates via title lookup
- Dead code and unused imports affecting maintainability

**Low**:
- Documentation drift from actual implementation behavior
- Lack of testable pure logic layer for core algorithms
- Limited structured logging for state transitions
- Unreliable lid detection heuristics

**Architecture Strengths**:
- Clean separation of concerns (monitoring, UI, configuration)
- IPC fallback mechanism for macOS compatibility
- Lock-based single-instance enforcement
- Comprehensive configuration management

---

## Appendix: Quick Reference

**Setup Command**: `bash setup.sh`
**Launch Method**: Double-click `WorkGuard.app`
**Stop Method**: `./stop_workguard.sh`

**Critical Code References**:
- Main loop: `work_guard.py:192` (_tick method)
- Activity detection: `monitor.py:205` (is_work_happening)
- Lock acquisition: `work_guard.py:50` (_acquire_lock)
- Config validation: `config.py:26` (validation logic)
- Overlays: `overlay.py:84` (overlay implementation)

**Development Notes**:
- Use Swift mode for macOS 26 compatibility (automatic detection)
- Never modify `self.title` in `_update_icon` (race condition)
- Test with `WORKGUARD_STATUS_WIDE=1` for menu bar diagnostics
- Always rebuild `WorkGuard.app` after project directory moves

**Testing Checklist**:
- Single-instance enforcement (duplicate launch notification)
- Pause/resume toggle functionality
- Configuration changes persistence
- Notifications (rumps and osascript fallbacks)
- Overlay display timing and dismissal
- Menu bar item visibility and interactions
- Swift mode IPC communication (if applicable)
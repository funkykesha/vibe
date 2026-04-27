# Project Brief — StartWatch

**What:** Native macOS menu bar + CLI tool. Monitors user-defined services after boot. Alerts on failure, supports auto-restart.

**Stack:** Swift 5.9+, SPM, AppKit, UNUserNotificationCenter, Network.framework. macOS 13+. Zero external dependencies.

**Artifact:** Single binary `startwatch`. Two modes: `startwatch daemon` (menu bar agent) and `startwatch <cmd>` (CLI).

**Config:** `~/.config/startwatch/config.json`  
**State/logs:** `~/.local/state/startwatch/`  
**LaunchAgent:** `~/Library/LaunchAgents/com.user.startwatch.plist`

**v1.0 scope:** 4 check types (port/http/process/command), 5 terminals, CLI commands (status/check/start/restart/config/log/doctor), notifications with actions, file-based IPC, LaunchAgent auto-start.

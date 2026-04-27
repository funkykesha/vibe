# Active Context

## Current State
v1.0 fully implemented and installed on the machine.  
Binary at `/usr/local/bin/startwatch`, LaunchAgent loaded.

## Last Session Work
- Built full project from scratch (Phases 0–7): all source files, tests, install script
- Fixed build errors: removed `-parse-as-library`, removed `@MainActor` from AppDelegate/MenuBarController
- Fixed `UNUserNotificationCenter` crash in CLI mode (guard on `Bundle.main.bundleIdentifier`)
- Fixed `install.sh` zsh color syntax (`$'\033'`)
- 19/19 tests passing, `swift build` clean (warnings only)
- User ran `bash install.sh` successfully — binary installed, LaunchAgent loaded
- `startwatch status` works, `startwatch doctor` works (no crash)

## Pending (approved plan: `/Users/agaibadulin/.claude/plans/flickering-toasting-star.md`)
1. **Create `README.md`** — onboarding docs (install, config guide, CLI reference, troubleshooting)
2. **Fix `install.sh` build output** — redirect warnings to `/tmp/startwatch-build.log`, only show on error
3. **Fix `install.sh` daemon startup** — add `launchctl kickstart` after bootstrap so daemon starts immediately without reboot

## Known Issues
- `startwatch doctor` shows `✗ Daemon is running` — LaunchAgent loaded but daemon not actually running (needs kickstart or relogin)
- Swift concurrency warnings in `ServiceChecker.swift` (captured `resumed` var) — warnings only, safe in Swift 5.9

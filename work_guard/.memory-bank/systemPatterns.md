# System Patterns

## Runtime Shape

- WorkGuard runtime center is the Python core (`work_guard.py`) running under the configured Conda `workguard` environment.
- UI helpers are separate processes when needed: Swift menu agent for reliable `NSStatusItem`, Tk settings subprocess, and PyObjC overlay subprocess.
- `~/.config/work_guard/` is the local coordination boundary: config, lock, logs, production-calendar cache, `status.json`, and `command.json`.
- Single-instance protection is the `fcntl` lock at `~/.config/work_guard/work_guard.lock`; every launch path must respect it.

## Launch And Install

- Public entrypoint is `bash rebuild.sh`.
- Supported GUI target is `/Applications/WorkGuard.app`.
- LaunchAgent contract is `~/Library/LaunchAgents/com.agaibadulin.workguard.plist` with `/usr/bin/open /Applications/WorkGuard.app`, `RunAtLoad=true`, `KeepAlive=false`.
- Direct Python launch is debug/diagnostics only.
- Legacy setup flow is obsolete; not a wrapper and not a fallback.
- Installed app remains a launcher to the configured Conda Python and project `work_guard.py`; it is not a standalone bundled Python application.
- Bundle templates and install-time assets belong in a dedicated packaging directory; project-local `.app` is not a supported launch target.

## External Boundaries

- macOS APIs provide foreground app, notifications, Accessibility-gated keyboard monitoring, display/lid hints, LaunchServices, and launchd.
- `xmlcalendar.ru` is the only intentional network dependency; fetched yearly calendar JSON is cached locally and can fall back to stale cache or configured weekdays.
- ActivitySignals are a future boundary only: local/coarse-only facts, no collectors yet.
- Nothing leaves the machine without an explicit user request; secrets never leave the machine.

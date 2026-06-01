Главное правило - финальный ответ должен быть на Русском!

# StartWatch — Agent Notes

## Menu Bar Icon

- macOS 26: sign `.app` with `codesign --force --deep --sign -`, else UI-agent not start (`RBSRequestErrorDomain Code=5`)
- After `CFBundleIdentifier` change run `killall SystemUIServer`, else icon may not appear
- Icon reset flow: `pkill -f startwatch` -> new `CFBundleIdentifier` in `StartWatchMenu.app/Contents/Info.plist` -> `codesign --force --deep --sign -` -> `killall SystemUIServer` -> `open -na ... --args menu-agent`
- Launch with `open -na App.app`, not direct binary path
- Full guide: `docs/macos-menubar-icon-guide.md`

## Deploy

- Do not run `install.sh` from agent: needs `sudo`, sandbox blocks. User runs manually: `! ./install.sh`
- `swift build` needs `dangerouslyDisableSandbox: true`
- Binary + `.app` live in `/Applications/` (not `/Applications/`)
- `/usr/local/bin/startwatch` is installed as Mach-O binary (not wrapper)
- LaunchAgent must run `/usr/local/bin/startwatch daemon` with label `com.user.startwatch`
- `install.sh` writes build warnings to `/tmp/startwatch-build.log`

## IPC

- Daemon -> Menu: `~/.config/startwatch/last_check.json` (polling path)
- Menu -> Daemon: `~/.config/startwatch/menu_command.json`

## Runtime Architecture

- `startwatch daemon` starts headless daemon + opens menu-agent as `.app` via `open`
- Menu UI + notifications must run in bundle process (`StartWatchMenu.app`), not daemon/CLI
- CLI commands (`doctor/status/check/...`) must route via `CLIRouter` even from `.app`, else hang in `NSApplication.run()`
- `startwatch status` reads cached last check; use `startwatch check` for live check

## LaunchAgent

- LaunchAgent plist: `com.user.startwatch.plist`
- After `install.sh`, agent may auto-start only after next login; immediate start: `startwatch daemon &`
- If icon missing after install, first verify both processes running: daemon + menu-agent

## Quick Debug

- App health: `startwatch doctor`
- Installer build logs: `/tmp/startwatch-build.log`
- Icon troubleshooting runbook: `docs/macos-menubar-icon-guide.md`

## Terminal Integration

- Warp auto-execute impossible without explicit user permission. URL scheme inserts text only. AppleScript keystroke needs Accessibility; Warp policy blocks.
- Final behavior: if Warp selected without Accessibility, show NSAlert with instructions + open `warp://action/new_tab` without command. See `docs/warp-terminal-integration.md`.
- `ProcessManager.stop(name:)` kills only StartWatch-managed processes. For external processes use `stop(service:)`: `pkill -f` (process type) or `lsof -ti tcp | xargs kill -9` (port/http type).

## Daemon Logging & Testing

- No daemon logging infra now: `print()` not visible in daemon output; stdout/stderr suppressed. Need file-based logging for daemon debugging.
- Priority: add logging layer + hotreload integration tests before next daemon-heavy work.

## Tests

- `swift test` must pass before commit

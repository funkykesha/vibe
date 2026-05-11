# Tech Context

## Build
```bash
swift build                  # debug
swift build -c release       # release (binary: .build/release/StartWatch)
swift test                   # run tests
```

## Install
```bash
bash install.sh              # builds, installs to /usr/local/bin, sets up LaunchAgent
```

## Binary Location
- Dev: `.build/debug/StartWatch`
- Release: `.build/release/StartWatch` (symlink to arch-specific)
- Installed CLI: `/usr/local/bin/startwatch` wrapper
- Installed app binary: `/Applications/StartWatchMenu.app/Contents/MacOS/startwatch` or `/Applications/StartWatchMenu.app/Contents/MacOS/startwatch`

## Key Paths
| Path | Purpose |
|------|---------|
| `~/.config/startwatch/config.json` | User config |
| `~/.local/state/startwatch/sock` | Unix socket IPC command/event stream |
| `~/.local/state/startwatch/last_check.json` | State checkpoint/fallback cache |
| `~/.local/state/startwatch/history.log` | Check history |
| `~/.config/startwatch/logs/events.json` | Structured runtime event log |
| `~/.local/state/startwatch/daemon.log` | LaunchAgent stdout log after install |
| `~/.local/state/startwatch/daemon-error.log` | LaunchAgent stderr log after install |
| `~/Library/LaunchAgents/com.user.startwatch.plist` | Auto-start |
| `/Applications/StartWatchMenu.app/` or `/Applications/StartWatchMenu.app/` | Menu bar .app bundle |
| `StartWatchMenu.app/Contents/MacOS/startwatch` | Single source-of-truth binary used by wrapper and LaunchAgent |

## Requirements
- macOS 13+
- Swift 5.9+ (`xcode-select --install`)
- No other dependencies

## Warnings (non-blocking)
- `ServiceChecker.swift`: Swift 6 Sendable warnings on `DispatchWorkItem` capture — safe in Swift 5.9 mode

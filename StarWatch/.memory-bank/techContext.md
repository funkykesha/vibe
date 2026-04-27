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
- Installed: `/usr/local/bin/startwatch`

## Key Paths
| Path | Purpose |
|------|---------|
| `~/.config/startwatch/config.json` | User config |
| `~/.local/state/startwatch/last_check.json` | IPC cache |
| `~/.local/state/startwatch/history.log` | Check history |
| `~/.local/state/startwatch/trigger_check` | IPC flag file |
| `~/Library/LaunchAgents/com.user.startwatch.plist` | Auto-start |

## Requirements
- macOS 13+
- Swift 5.9+ (`xcode-select --install`)
- No other dependencies

## Warnings (non-blocking)
- `ServiceChecker.swift`: Swift 6 Sendable warnings on `DispatchWorkItem` capture — safe in Swift 5.9 mode

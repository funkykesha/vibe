# Progress

## Done
- [x] Phase 0: Package.swift, Config models, ConfigManager, config.example.json
- [x] Phase 1: ServiceChecker (4 types), ServiceRunner, StateManager, HistoryLogger, AsyncHelpers
- [x] Phase 2: ANSIColors, TableFormatter, ReportBuilder, CLIRouter, all 8 CLI commands
- [x] Phase 3: AppDelegate, MenuBarController, CheckScheduler
- [x] Phase 4: TerminalProtocol + 5 adapters (Warp/iTerm/Terminal/Alacritty/Kitty), TerminalLauncher
- [x] Phase 5: NotificationManager (UNUserNotificationCenter, categories, actions)
- [x] Phase 6: IPCMessage, IPCClient (file-based), IPCServer (flag polling)
- [x] Phase 7: main.swift routing, com.user.startwatch.plist, install.sh
- [x] Tests: ConfigTests, ServiceCheckerTests, FormattingTests (19/19 pass)
- [x] Build fixes: -parse-as-library removed, @MainActor issue fixed
- [x] Runtime fixes: notification crash in CLI, install.sh color codes
- [x] Installed on machine and verified working

## In Progress
- [ ] README.md (approved, not started)
- [ ] install.sh: suppress build warnings
- [ ] install.sh: auto-start daemon via kickstart

## Backlog (v1.1)
- Unix socket IPC (replace file-based)
- Swift 6 concurrency fix in ServiceChecker (replace DispatchWorkItem with actor)
- Settings window (SwiftUI)
- TOML/YAML config support

## 1. App Launch Routing

- [x] 1.1 Update app-bundle no-argument routing so double-click launches menu-agent behavior instead of CLI status fallback.
- [x] 1.2 Add daemon-readiness ensure step for app-bundle launch using LaunchAgent bootstrap/kickstart semantics.
- [x] 1.3 Make repeated app launches idempotent so only one persistent menu-agent/status item is active.
- [x] 1.4 Preserve explicit CLI command routing from the bundle binary for `status`, `check`, `doctor`, `config`, `log`, `start`, `restart`, `help`, and `version`.

## 2. LaunchAgent And Installer Source Of Truth

- [x] 2.1 Update `com.user.startwatch.plist` template to use `/Applications/StartWatchMenu.app/Contents/MacOS/startwatch daemon --no-menu`.
- [x] 2.2 Simplify `install.sh` so LaunchAgent installation uses the final bundle-binary daemon path without sed rewriting from `/usr/local/bin/startwatch`.
- [x] 2.3 Keep `CFBundleIdentifier` stable during normal install and remove default bundle id rotation.
- [x] 2.4 Keep CLI wrapper as a thin exec into the bundle binary for user CLI commands.

## 3. Daemon And Menu-Agent Ownership

- [x] 3.1 Remove daemon periodic menu-agent respawn from normal LaunchAgent operation.
- [x] 3.2 Ensure `daemon --no-menu` never attempts to spawn menu-agent.
- [x] 3.3 Keep daemon monitoring, IPC, config watching, and service checking functional after UI spawn removal.
- [x] 3.4 Add or update logging for daemon headless startup and skipped UI ownership.

## 4. Notification Boundary

- [x] 4.1 Remove direct daemon calls to `NotificationManager.shared` for failed, recovered, and invalid-config notification delivery.
- [x] 4.2 Move notification emission to menu-agent based on daemon-written state or existing IPC/state observation.
- [x] 4.3 Keep `NotificationManager` guarded so CLI, daemon, and test contexts never call `UNUserNotificationCenter.current()`.
- [x] 4.4 Preserve notification actions for opening CLI and restarting failed services from the app/menu-agent context.

## 5. Stop And Quit Lifecycle

- [x] 5.1 Update CLI `startwatch stop` to request daemon shutdown and terminate any remaining menu-agent process.
- [x] 5.2 Update menu-agent quit flow so UI terminates itself after sending daemon quit request.
- [x] 5.3 Verify daemon shutdown still cancels daemon-owned timers, scheduled checks, IPC server, and pending work items.
- [ ] 5.4 Ensure clean stop leaves no `startwatch daemon` or `startwatch menu-agent` process.

## 6. Verification

- [x] 6.1 Add or update tests for app-bundle command routing and CLI commands not entering `NSApplication.run()`.
- [x] 6.2 Add or update tests for `NotificationManager` safety outside app bundle and daemon notification boundary behavior.
- [x] 6.3 Run `swift test` and confirm all tests pass.
- [ ] 6.4 Manually verify installed app: double-click `/Applications/StartWatchMenu.app`, confirm one menu-agent and one daemon.
- [ ] 6.5 Manually verify LaunchAgent: `launchctl print gui/$(id -u)/com.user.startwatch` shows bundle binary with `daemon --no-menu`.
- [ ] 6.6 Manually verify `startwatch stop` exits daemon and menu-agent.

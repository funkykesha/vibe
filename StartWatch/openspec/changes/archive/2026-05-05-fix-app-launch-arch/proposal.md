## Why

StartWatch is installed as a macOS app bundle, but launching `/Applications/StartWatchMenu.app` like a normal app only starts the menu UI and does not ensure the daemon is alive. The current runtime boundary also lets the daemon own UI spawning and notification delivery, which caused silent launches and daemon crashes in installed environments.

## What Changes

- Make double-click app launch start the menu-agent and ensure the LaunchAgent-backed daemon is running.
- Make LaunchAgent own only the headless daemon process, using the app bundle binary with `daemon --no-menu`.
- Stop the daemon from owning persistent menu-agent lifecycle and periodic UI respawn.
- Keep UserNotifications ownership in the app/menu-agent process; daemon must not call macOS notification APIs directly.
- Make install artifacts use stable app identity and one source of truth for the bundle binary path.
- Ensure `startwatch stop` terminates both daemon and menu-agent without leaving orphan UI.

## Capabilities

### New Capabilities
- `macos-app-launch`: Normal macOS app launch behavior for `/Applications/StartWatchMenu.app`, including double-click daemon readiness and idempotent UI startup.

### Modified Capabilities
- `headless-daemon-mode`: LaunchAgent daemon runs headless with `--no-menu`, and daemon no longer owns persistent menu-agent respawn.
- `notification-test-stability`: Notification delivery is limited to real app/menu-agent context; daemon does not touch UserNotifications.
- `clean-process-exit`: Stop and quit flows terminate daemon and menu-agent consistently.

## Impact

- Affected code: `Sources/StartWatch/main.swift`, `Sources/StartWatch/Daemon/AppDelegate.swift`, `Sources/StartWatch/MenuAgent/*`, notification integration, stop/quit commands, LaunchAgent template, `install.sh`.
- Affected runtime systems: macOS LaunchAgent, LaunchServices app launch, menu bar UI process, daemon process, notification permissions.
- No external dependency changes expected.

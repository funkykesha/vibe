## Why

macOS notifications currently show only service names when something fails ("Not running: Redis") with no context about what went wrong. Users have to manually open CLI to understand the cause, and there's no notification when a service recovers. Additionally, the config FileWatcher uses timer polling which misses atomic saves from VSCode/vim, and config access has a latent thread-safety bug.

## What Changes

- Notifications now include the failure reason from `detail` field (e.g., "Port 6379 not responding")
- New notification when services recover ("Service Recovered: Redis")
- New notification when saved config fails validation ("Config Error: ...")
- New `showFailureDetails: Bool?` flag in `NotificationsConfig` to control detail visibility
- `sound: Bool?` flag now respected by all notification types
- `onlyOnFailure` does not suppress "recovered" notifications
- Notifications fire only on status changes, not on daemon startup
- Services in `isStarting` state do not trigger failure notifications (anti-spam)
- FileWatcher replaced: Timer polling → FSEvents watching the config directory
- Debounce 200ms added to FileWatcher to handle rapid saves
- `configQueue` barrier pattern applied correctly for thread-safe config access
- `fw.log` debug file removed

## Capabilities

### New Capabilities

- `rich-service-notifications`: macOS notifications with failure reasons, recovery events, and config validation errors — replacing the current name-only failure alerts

### Modified Capabilities

<!-- No existing spec-level behavior changes -->

## Impact

- `Sources/StartWatch/Core/FileWatcher.swift` — full rewrite
- `Sources/StartWatch/Core/Config.swift` — add `showFailureDetails` field
- `Sources/StartWatch/Notifications/NotificationManager.swift` — expand API
- `Sources/StartWatch/Daemon/AppDelegate.swift` — thread safety + notification logic
- `docs/adr/0001-filewatcher-directory-over-file.md` — new ADR
- No breaking changes to CLI or config format (new optional field, backward-compatible)

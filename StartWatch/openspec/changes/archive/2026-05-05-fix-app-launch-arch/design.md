## Context

StartWatch currently packages one SwiftPM-built binary into `/Applications/StartWatchMenu.app` and uses runtime arguments to select CLI, daemon, or menu-agent mode. The installed app bundle is valid and codesigned, but a no-argument app launch only enters menu-agent mode. Monitoring depends on a separate LaunchAgent-started daemon.

Runtime ownership is inverted for a normal macOS app: the daemon starts and periodically respawns the menu UI, while the app launch path does not ensure daemon readiness. Daemon code also calls notification APIs, which are only safe in a real app bundle context. Installed logs show `UNUserNotificationCenter` crashing when `mainBundle.bundleURL` resolves outside the app bundle.

Constraints:

- Keep the single-binary packaging model.
- Keep CLI commands routed through `CLIRouter`.
- Keep menu UI and macOS notifications in the app bundle process.
- Avoid speculative packaging systems or new dependencies.
- Preserve existing install location `/Applications/StartWatchMenu.app`.

## Goals / Non-Goals

**Goals:**

- Double-clicking `/Applications/StartWatchMenu.app` starts the visible menu-agent and ensures the daemon is running.
- LaunchAgent manages only the headless daemon lifecycle.
- Daemon no longer owns persistent menu-agent respawn.
- Daemon does not call `UNUserNotificationCenter`.
- Installer and LaunchAgent use one stable bundle-binary path and stable bundle identity.
- Stop/quit flows leave no daemon or menu-agent orphan.

**Non-Goals:**

- Replacing SwiftPM packaging with an Xcode project.
- Renaming the app bundle or moving it out of `/Applications`.
- Adding privileged helpers, login items, or new external dependencies.
- Redesigning service checking, IPC protocol payloads, or menu UI states beyond launch lifecycle needs.

## Decisions

### App launch owns UI and daemon readiness

No-argument app-bundle launches will run the menu-agent and trigger daemon readiness through LaunchAgent. This matches user expectations for double-click launch: visible UI appears and monitoring is active.

Alternative considered: keep daemon as UI owner and require users to start daemon first. Rejected because it makes the app bundle a secondary implementation detail instead of the primary macOS launch surface.

### LaunchAgent owns headless daemon only

The LaunchAgent will point directly to `/Applications/StartWatchMenu.app/Contents/MacOS/startwatch` with `daemon --no-menu`. This prevents daemon-started UI loops and keeps process ownership explicit.

Alternative considered: LaunchAgent starts `daemon` without `--no-menu` and daemon opens the menu-agent. Rejected because it duplicates UI ownership and conflicts with double-click app semantics.

### Notifications are delivered by menu-agent

Daemon must not invoke `UNUserNotificationCenter`. It can write status/cache/events through existing state and IPC mechanisms; the menu-agent observes state and emits user notifications from the app bundle process.

Alternative considered: keep guards around `NotificationManager` in daemon. Rejected because the installed crash shows context can still drift, and notification permissions are app identity concerns.

### Stable bundle identity by default

The installer will keep `CFBundleIdentifier` stable and reserve LaunchServices/SystemUIServer resets for troubleshooting. Stable identity preserves notification permissions and avoids changing user trust state on every install.

Alternative considered: rotate bundle id on each install to work around stale menu bar icon cache. Rejected as default behavior because it trades one debug workaround for recurring identity churn.

### Stop targets both runtime processes

CLI stop should terminate daemon and menu-agent, not just send daemon IPC. Menu-agent-initiated quit can still send IPC first, then terminate itself after daemon shutdown is requested.

Alternative considered: rely on daemon shutdown to indirectly end UI. Rejected because daemon no longer owns UI lifecycle.

## Risks / Trade-offs

- LaunchAgent bootstrap may fail if not installed or stale → menu-agent should surface a daemon-not-running state and install flow should reload LaunchAgent explicitly.
- Removing daemon UI respawn changes previous recovery behavior → double-click app launch becomes the supported UI recovery path; LaunchAgent remains daemon recovery path.
- Moving notifications to menu-agent can delay alerts until menu-agent is running → menu-agent should be launched at login by user action or kept visible through the normal app surface; daemon continues writing state for later observation.
- Stable bundle id can leave stale menu bar cache during development → document manual reset steps instead of rotating identity by default.

## Runtime Invariants (Must Hold)

1. Exactly one daemon process:
   - owner: `launchd` job `gui/<uid>/com.user.startwatch`
   - argv contains `daemon --no-menu`
2. At most one persistent menu-agent process:
   - owner: user app launch (`open -na ... --args menu-agent`) or explicit menu-agent command
   - duplicate launch attempts must early-exit before creating a second status item
3. Daemon never calls UI/notification APIs (`NSApplication`, `UNUserNotificationCenter`).
4. `startwatch stop` is global stop:
   - unload/bootout LaunchAgent first
   - terminate residual daemon/menu-agent processes
   - post-condition: no `startwatch daemon` and no `startwatch menu-agent`

## Diagnostics From Current Failure Mode

Observed logs show two classes of problems:

1. Multiple menu-agent PIDs simultaneously (`pgrep -fal "startwatch menu-agent"`).
2. FrontBoard scene churn (`No matching scene to invalidate`, repeated `NSSceneFenceAction`) and intermittent invisible status item.

Interpretation:

- Duplicate menu-agent processes create competing status item scenes.
- Scene reconnect storms are a downstream effect, not a root cause.
- LaunchAgent currently still runs `daemon` without guaranteed `--no-menu` in installed runtime, so lifecycle ownership can split between daemon and app launch.

## Migration Plan

1. Enforce installed LaunchAgent command line:
   - `.../StartWatchMenu.app/Contents/MacOS/startwatch daemon --no-menu`
2. Enforce menu-agent singleton guard:
   - first instance keeps running
   - subsequent launches exit quickly with log reason
3. Harden stop path:
   - `launchctl bootout gui/<uid>/com.user.startwatch`
   - then targeted `pkill` fallback for `startwatch daemon|menu-agent`
4. Re-bootstrap once after install/update:
   - `launchctl bootstrap` / `kickstart -k`
5. Validate process graph:
   - one daemon PID, one menu-agent PID, stable over repeated app launches

## Manual Recovery Runbook (When Cache/UI Is Stale)

Use only as troubleshooting, not default install behavior:

1. `pkill -f startwatch`
2. reinstall/reload LaunchAgent
3. if icon is still missing, run `killall SystemUIServer`
4. relaunch app via `open -na /Applications/StartWatchMenu.app --args menu-agent`

This keeps stable bundle identity as default while retaining a deterministic operator path when macOS status item caching misbehaves.

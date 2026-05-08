## Why

Current daemon startup relies on CLI bootstrap hacks (`open -na ... menu-agent`) that can spawn duplicate processes and create startup race conditions. We need launchd-owned lifecycle so daemon availability is deterministic at login and clients only connect.

## What Changes

- Add LaunchAgent-based daemon lifecycle with explicit install/uninstall command flow.
- Remove CLI bootstrap behavior that starts app bundles when IPC socket is missing.
- Make menu-agent a pure UI client that shows daemon-offline state and offers daemon start action.
- Add graceful SIGTERM handling in daemon shutdown path so launchd stop/restart preserves consistent state.

## Capabilities

### New Capabilities
- `launchagent-daemon-lifecycle`: Define daemon ownership by launchd, CLI install/uninstall lifecycle, client behavior when daemon is offline, and graceful termination guarantees.

### Modified Capabilities
None.

## Impact

- Affected code: CLI command routing, IPC client behavior, menu-agent startup behavior, daemon lifecycle handling, installer integration.
- New CLI surface: `startwatch install`, `startwatch uninstall`.
- Affected system integration: `~/Library/LaunchAgents`, `launchctl bootstrap/bootout/kickstart`.

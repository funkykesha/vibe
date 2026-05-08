## Why

StartWatch launch and stop paths currently produce different runtime behavior, so users get inconsistent results depending on whether they launch via `.app`, CLI, or LaunchAgent. This causes missing menu UI, duplicate daemon risks, and unclear ownership of service lifecycle.

## What Changes

- Unify runtime lifecycle so one startup contract exists for app-bundle launch and CLI daemon launch.
- Keep daemon core and menu UI in one process for full mode; keep headless daemon mode via `--no-menu`.
- Keep Unix socket IPC as CLI-to-daemon transport and as menu control transport when UI starts as non-owner client.
- Ensure stop actions (`startwatch stop` and menu Quit) both shut down services, daemon, and UI cleanly.
- Update LaunchAgent execution path to use `/usr/local/bin/startwatch daemon --no-menu` instead of app-bundle binary.
- Add race-safe daemon ownership model based on socket bind outcome (`EADDRINUSE` handling) instead of pre-check-only logic.
- Add UI-only client mode: if daemon already owns socket, app launch starts menu and controls daemon via IPC client, without creating second coordinator.

## Capabilities

### New Capabilities
- `unified-app-lifecycle`: One-process lifecycle contract for full mode (daemon + menu + services) with deterministic startup/shutdown behavior.

### Modified Capabilities
- None.

## Impact

- Affected code: launch routing (`main.swift`), daemon coordinator lifecycle, menu-agent integration points, LaunchAgent/install wiring, and related tests.
- Affected behavior: startup matrix, stop matrix, bind-time race handling, single-instance handling, and menu visibility reliability.
- External dependencies: no new third-party dependencies; LaunchAgent plist behavior changes.

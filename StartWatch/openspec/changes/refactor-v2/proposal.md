## Why

StartWatch currently derives process role from runtime socket ownership, which allows ambiguous states such as menu-owner, daemon-with-menu, and daemon-non-owner. This ambiguity contributes to menu disappearance after reinstall and makes macOS app-bundle registration, LaunchAgent behavior, and service lifecycle ownership fragile.

## What Changes

- **BREAKING**: Replace socket-ownership role selection with fixed launch-context routing:
  - `.app` bundle always runs Menu Agent.
  - `startwatch daemon` always runs headless daemon runtime.
  - all other invocations run short-lived CLI client behavior.
- **BREAKING**: Replace `/usr/local/bin/startwatch` wrapper with the real Mach-O binary; installer deploys one build artifact as two physical copies: `/usr/local/bin/startwatch` and `/Applications/StartWatchMenu.app/Contents/MacOS/startwatch`.
- **BREAKING**: LaunchAgent `com.user.startwatch` runs `/usr/local/bin/startwatch daemon`; `--no-menu` and bundle-binary LaunchAgent paths are removed.
- Introduce raw short-lived typed IPC request/response for PR1-6; length-prefix framing and persistent subscribe are deferred to a later stage.
- Move service lifecycle ownership to daemon: CLI/Menu request actions over IPC; daemon starts/stops/restarts background services and returns terminal-execution responses for interactive services.
- Add optional `stop` command to service config and define daemon-side stop fallback using discovered PID/port with SIGTERM grace then SIGKILL.
- Split global daemon lifecycle from service lifecycle:
  - `startwatch stop <name>` stops a service.
  - `startwatch quit` stops daemon.
  - Menu has separate `Quit Menu` and `Stop Daemon`.
- Keep Menu state polling in PR1-6 with explicit online/offline intervals and offline stale-state display from checkpoint.
- Add installer, migration, troubleshooting, IPC protocol, and architecture documentation for the new runtime model.

## Capabilities

### New Capabilities
- `role-based-runtime-routing`: Fixed process role selection by launch context, one build artifact with two installed copies, and AppKit boundary rules.
- `typed-short-lived-ipc`: Raw Codable JSON request/response IPC for PR1-6 with EOF-based request termination.
- `service-control-contract`: Daemon-owned service lifecycle contract, including `background`, `stop`, terminal handoff, and offline behavior.
- `runtime-installation-contract`: Installer, LaunchAgent, socket-permission, exit-code, and restart-throttle requirements for the refactored runtime.
- `refactor-v2-documentation`: Required docs for architecture, IPC protocol, installer behavior, migration, and troubleshooting.

### Modified Capabilities
- `headless-daemon-mode`: Remove `--no-menu`, remove daemon/menu ownership variants, and require daemon runtime to be headless by role.
- `macos-app-launch`: App bundle launch always runs Menu Agent and never routes CLI commands from inside the bundle.
- `launchagent-daemon-lifecycle`: LaunchAgent runs `/usr/local/bin/startwatch daemon` with `KeepAlive={SuccessfulExit=false}` and `ThrottleInterval=10`.
- `runtime-installation-contract`: Add LaunchServices refresh with best-effort `lsregister -f` and doctor validation that bundle id resolution points to `/Applications/StartWatchMenu.app`.
- `typed-short-lived-ipc`: Add IPC client connect/response timeouts and distinguish daemon-offline from daemon-unresponsive failures.
- `ipc-unix-socket`: Replace PR1-6 active IPC framing/streaming behavior with short-lived raw JSON request/response.
- `clean-process-exit`: Split service stop from daemon quit and define clean exit code behavior under launchd.
- `restart-live-output`: Make `restart all/failed` daemon-online-only and orchestrated through `getStatus` plus per-service IPC actions.
- `adaptive-menu-polling`: For PR1-6, Menu uses timer polling instead of live subscribe; push returns in a later stage.
- `bidirectional-ipc-state-stream`: Defer persistent subscribe/event-stream behavior out of PR1-6.
- `startup-state-propagation`: Remove CLI-owned lifecycle state writes; daemon remains the state writer.
- `service-lifecycle-logging`: Add logging/visibility for skipped terminal autostart and new stop behavior.

## Impact

- Affected runtime files: process entrypoint, daemon coordinator/runtime, menu delegate/control plane, CLI commands, IPC client/server/transport, installer, doctor, and tests.
- Affected public behavior: CLI command semantics, LaunchAgent plist, installer output, config schema, IPC wire format, menu offline behavior, and restart/stop lifecycle behavior.
- Affected documentation: architecture, IPC protocol, installer, migration, troubleshooting, and project agent notes.
- No new third-party dependencies are expected.

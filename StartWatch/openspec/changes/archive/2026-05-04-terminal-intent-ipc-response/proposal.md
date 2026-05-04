## Why

Service start/restart flows still rely on daemon-driven process control without an explicit response contract for interactive terminal launches. This creates brittle behavior and prevents a clean split where daemon stays headless and UI contexts handle terminal opening.

## What Changes

- Add a typed IPC service response for start/restart operations: `ok`, `executeInTerminal`, and `error`.
- Add `TerminalCommand` payload for interactive service starts, including service name and command context.
- Add `background: Bool?` to service config to explicitly choose daemon background execution vs interactive terminal intent.
- Update daemon start/restart handlers to return response values instead of fire-and-forget side effects only.
- Keep CLI interactive starts in current terminal (`ServiceRunner.exec`) and route only background starts via IPC response.
- Require menu-agent terminal execution to run on main thread when processing terminal intent.

## Capabilities

### New Capabilities
- `terminal-intent-handoff`: Daemon can return a terminal-execution intent to menu-agent/CLI instead of opening terminals itself.

### Modified Capabilities
- `ipc-unix-socket`: Start/restart IPC paths become request/response for typed service outcomes.
- `headless-daemon-mode`: Daemon responsibilities are clarified to avoid terminal-launch ownership on start/restart flows.

## Impact

- Affected code: IPC client/server, daemon coordinator callbacks, service config model, menu-agent start/restart handling, CLI start/restart commands.
- API impact: internal IPC wire protocol changes for start/restart message handling.
- Behavior impact: clearer split of background vs interactive service startup using explicit config.

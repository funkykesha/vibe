# StartWatch Architecture (refactor-v2)

## Runtime Routing

StartWatch uses one executable artifact and fixed launch-context routing:

- `.app` bundle launch -> **Menu Agent** only.
- `/usr/local/bin/startwatch daemon` -> **headless daemon runtime** only.
- Non-bundle invocation with no args -> `startwatch status`.
- Other non-bundle invocations -> CLI via `CLIRouter`.

Socket ownership is no longer used to choose UI/runtime role.

## Separation Of Responsibilities

- `DaemonRuntime`:
  - config loading/reload
  - scheduler/check execution
  - in-memory state + checkpoint flush
  - IPC server handlers
  - background service lifecycle
- `MenuAgentDelegate` + `MenuBarController`:
  - NSStatusItem/menu rendering
  - daemon online/offline polling
  - notifications
  - menu action dispatch over IPC
- CLI:
  - short-lived commands over IPC
  - no local ownership fallback for lifecycle actions

## IPC Model (PR1-6)

- Transport: Unix socket `~/.local/state/startwatch/sock`.
- Request/response is short-lived typed JSON (`IPCRequest`/`IPCResponse`).
- One request per connection:
  - write JSON request
  - `shutdown(SHUT_WR)`
  - read one JSON response
  - close
- Active behavior does not require `subscribe`/length-prefix streaming.

## Installer And Deployment Contract

- Same built Mach-O copied to:
  - `/usr/local/bin/startwatch`
  - `/Applications/StartWatchMenu.app/Contents/MacOS/startwatch`
- App bundle is replaced on install, signed ad-hoc, and registered with LaunchServices (`lsregister -f`).
- LaunchAgent:
  - label: `com.user.startwatch`
  - args: `/usr/local/bin/startwatch daemon`
  - `RunAtLoad=true`
  - `KeepAlive={SuccessfulExit=false}`
  - `ThrottleInterval=10`
  - logs in `~/.local/state/startwatch`

## AppKit Boundary

Daemon/core runtime files must not depend on AppKit UI APIs or `TerminalLauncher`.
Boundary check script:

```bash
./scripts/check-daemon-boundary.sh
```

## Menu Polling

- Poll every 3s when daemon is online.
- Poll every 5s when daemon is offline.
- Immediate refresh after service action / trigger check.
- Offline view keeps last known checkpoint-derived state and stale age.

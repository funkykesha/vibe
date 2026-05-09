
## 1. Routing and Runtime Boundaries

- [ ] 1.1 Refactor `main.swift` routing so `.app` bundle always starts Menu Agent, non-bundle `daemon` starts headless daemon, empty non-bundle args route to `status`, and all other non-bundle invocations route to CLI.
- [ ] 1.2 Remove active use of `StartupPlanner`, `showMenu`, `--no-menu`, owner-with-menu, client-with-menu, and duplicate-headless runtime branches.
- [ ] 1.3 Replace `DaemonCoordinator` role/ownership API with headless `DaemonRuntime` semantics while preserving scheduler, config loading, checks, state, and IPC handlers.
- [ ] 1.4 Remove `LocalMenuControlPlane`; keep one IPC-backed `MenuControlPlane` implementation for Menu actions.
- [ ] 1.5 Add boundary static-check script for daemon/core files rejecting AppKit UI symbols and `TerminalLauncher` references.

## 2. Installer and LaunchAgent

- [ ] 2.1 Update `install.sh` to copy the release Mach-O directly to `/usr/local/bin/startwatch`, overwriting any wrapper unconditionally.
- [ ] 2.2 Update `install.sh` to replace `/Applications/StartWatchMenu.app`, copy the same Mach-O into `Contents/MacOS/startwatch`, preserve bundle id `com.user.startwatch.menu`, and ad-hoc codesign the bundle.
- [ ] 2.3 Update checked-in and generated LaunchAgent plist to label `com.user.startwatch` and `ProgramArguments` `/usr/local/bin/startwatch daemon`.
- [ ] 2.4 Add LaunchAgent `RunAtLoad=true`, `KeepAlive={SuccessfulExit=false}`, `ThrottleInterval=10`, and daemon log paths under `~/.local/state/startwatch`.
- [ ] 2.5 Ensure state directory creation uses mode `0700` and daemon socket file is created with effective mode `0600`.
- [ ] 2.6 Update `startwatch install` to repair/bootstrap LaunchAgent only and not perform build, copy, or codesign work.
- [ ] 2.7 Update `doctor` to validate Mach-O CLI path, `/Applications` app bundle, LaunchAgent args, KeepAlive, ThrottleInterval, codesign, and socket permissions.
- [ ] 2.8 Run `lsregister -f /Applications/StartWatchMenu.app` after app bundle copy and before `open -na`; log failures non-fatally.
- [ ] 2.9 Add `doctor` check that LaunchServices resolves `com.user.startwatch.menu` to `/Applications/StartWatchMenu.app`.

## 3. IPC Protocol

- [ ] 3.1 Introduce typed `IPCRequest` and `IPCResponse` Codable enums with raw JSON shapes for start, stop, restart, triggerCheck, getStatus, quit, statusSnapshot, executeInTerminal, ok, and error.
- [ ] 3.2 Refactor `UnixSocketTransport`, `IPCClient`, and `ClientConnection` active request path to one raw JSON request, `shutdown(SHUT_WR)`, one raw JSON response, and close.
- [ ] 3.3 Remove length-prefix framing from the active PR1-6 request/response path while keeping or deleting frame code only if it is not wired into active behavior.
- [ ] 3.4 Remove active Menu dependency on persistent `subscribe` and `serviceChanged`; ensure no `subscribe` handler is required for PR1-6 Menu operation.
- [ ] 3.5 Implement `getStatus` response from daemon in-memory snapshot and `triggerCheck` as async check scheduling with immediate `ok`.
- [ ] 3.6 Ensure lifecycle IPC calls fail with daemon-offline errors instead of bootstrapping app bundle or falling back to local execution.
- [ ] 3.7 Implement `IPCClient` connect timeout 3s and response timeout 5s; distinguish daemon-offline from daemon-unresponsive in error reporting.
- [ ] 3.8 Remove `menu_command.json` file transport entirely; ensure no code path reads or writes it.

## 4. Service Lifecycle

- [ ] 4.1 Add optional `stop: String?` to `ServiceConfig` with backward-compatible decoding and encoding.
- [ ] 4.2 Implement daemon-owned `startService` and `restartService`: background services run through `ProcessManager`; non-background services return `executeInTerminal(command, workingDirectory?, serviceName)`.
- [ ] 4.3 Implement daemon-owned `stopService`: explicit `stop` command first, managed PID second, discovered port/process PID third, otherwise `error("no stoppable target")`.
- [ ] 4.4 Implement stop escalation: SIGTERM, 5-second grace, then SIGKILL if the target is still alive.
- [ ] 4.5 Update CLI `start`, `restart <name>`, and Menu service actions to process `ok`, `executeInTerminal`, and `error` responses.
- [ ] 4.6 Update CLI `stop <name>` to send `stopService`; make `startwatch stop` without a name fail with `Did you mean 'startwatch quit'?`.
- [ ] 4.7 Add `startwatch quit` to send daemon `quit` and keep Menu Agent running offline.
- [ ] 4.8 Update `restart all` and `restart failed` to require daemon online, call `getStatus`, filter targets, send `restartService` per target, and never call `ProcessManager` or foreground checks for lifecycle decisions.
- [ ] 4.9 Keep `startwatch check` foreground-output behavior while optionally sending async `triggerCheck`.

## 5. Menu Behavior

- [ ] 5.1 Ensure Menu Agent creates `NSStatusItem` immediately before daemon connection succeeds.
- [ ] 5.2 Implement timer refresh every 3 seconds when daemon is online and every 5 seconds when offline.
- [ ] 5.3 Refresh Menu immediately after service actions and `triggerCheck`.
- [ ] 5.4 Implement offline view with `Daemon offline`, disabled lifecycle actions, `Start Daemon`, and last-known checkpoint services.
- [ ] 5.5 Derive offline stale age from checkpoint snapshot timestamp when present, falling back to `last_check.json` file mtime.
- [ ] 5.6 Implement Menu `Start Daemon` as `launchctl kickstart gui/$(id -u)/com.user.startwatch` only.
- [ ] 5.7 Split Menu actions into `Quit Menu` (terminate app only) and `Stop Daemon` (send daemon `quit`).
- [ ] 5.8 Keep notifications owned by Menu Agent and driven from refreshed service state.

## 6. Validation, Logging, and Visibility

- [ ] 6.1 Add ConfigManager warning for `autostart=true` with `background!=true` without auto-converting config.
- [ ] 6.2 Make daemon skip terminal autostart services and log structured reason `autostart skipped: requires background=true`.
- [ ] 6.3 Surface skipped terminal autostart in `doctor` output.
- [ ] 6.4 Surface skipped terminal autostart as per-service Menu detail.
- [ ] 6.5 Add structured logs for service stop attempts, stop strategy, SIGKILL escalation, stop success, and no-stoppable-target errors.

## 7. Documentation

- [ ] 7.1 Update `docs/architecture.md` for role separation, one build artifact/two copies, AppKit boundary, raw PR1-6 IPC, and timer-polling Menu state.
- [ ] 7.2 Create `docs/IPC_PROTOCOL.md` with request/response JSON shapes, EOF shutdown behavior, and Stage III framing/subscribe roadmap.
- [ ] 7.3 Create `docs/INSTALLER.md` with `/usr/local/bin` Mach-O, `/Applications` bundle, codesign, LaunchAgent keys, exit codes, and socket permissions.
- [ ] 7.4 Create `docs/MIGRATION.md` for CLI, config, IPC, wrapper-removal, autostart, and `startwatch` no-args changes.
- [ ] 7.5 Create `docs/TROUBLESHOOTING.md` for stale socket, launchd permissions, offline recovery, kickstart, and intentional vs failure exits.
- [ ] 7.6 Update project notes that still say LaunchAgent must run the bundle binary or that `/usr/local/bin/startwatch` is a wrapper.

## 8. Tests and Verification

- [ ] 8.1 Add routing unit tests for app-bundle Menu routing, daemon routing, empty-args status routing, and CLI no-NSApplication behavior.
- [ ] 8.2 Add daemon startup tests for bind success, live duplicate exit 0, stale socket recovery, and fatal bind/path error exit 1.
- [ ] 8.3 Add IPC tests for raw Codable JSON shapes, EOF shutdown, getStatus, triggerCheck, lifecycle responses, quit, and no active length-prefix/subscribe behavior.
- [ ] 8.4 Add service lifecycle tests for background execution, non-background terminal handoff, stop command priority, PID/port fallback, SIGTERM-to-SIGKILL escalation, offline failures, and restart all/failed via getStatus.
- [ ] 8.5 Add installer/doctor tests for plist args, KeepAlive, ThrottleInterval, Mach-O path, app bundle id, codesign checks, wrapper overwrite, socket permissions, `lsregister -f` running after bundle copy, and doctor LaunchServices resolution check.
- [ ] 8.6 Add validation/logging tests for skipped terminal autostart and stop behavior logs.
- [ ] 8.7 Run `swift test`, `zsh -n install.sh`, generated plist parse check, boundary static-check script, and markdown formatting checks for edited docs.


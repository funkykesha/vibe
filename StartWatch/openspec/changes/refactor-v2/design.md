## Context

StartWatch is one SwiftPM executable target used as CLI, daemon, and AppKit menu app. The current runtime chooses owner/client roles from socket bind outcome and `showMenu`, producing states such as owner-with-menu, client-with-menu, duplicate-headless, and daemon-with-menu. That made the installer and macOS app registration fragile: the LaunchAgent may run the bundle binary, `/usr/local/bin/startwatch` may be a wrapper, and explicit CLI commands can be routed from inside the `.app` bundle.

The refactor fixes the role model rather than patching LaunchServices symptoms. Process role is selected only from launch context; the Unix socket becomes IPC only, not role arbitration.

## Goals / Non-Goals

**Goals:**
- Make runtime roles deterministic: `.app` means Menu, `daemon` means headless daemon, everything else means CLI.
- Keep one SwiftPM executable target and one build artifact, installed as two physical copies.
- Make `/usr/local/bin/startwatch` the real CLI/LaunchAgent Mach-O binary, not a wrapper.
- Keep daemon free of AppKit/UI object creation by file/runtime boundary.
- Move service lifecycle ownership to daemon and use typed short-lived IPC for commands.
- Keep Menu live state simple for PR1-6: timer polling and checkpoint fallback; defer push subscriptions to a later stage.
- Document the migration, installer, IPC protocol, troubleshooting, and architecture changes.

**Non-Goals:**
- Split into multiple SwiftPM targets or multiple executable products in this change.
- Introduce XPC or SMAppService.
- Preserve IPC backward compatibility for old clients.
- Implement persistent subscribe/push event streams or length-prefix framing in PR1-6.
- Make daemon launch terminals or own macOS notifications.

## Decisions

### Decision 1: Role is selected by launch context

The entrypoint checks `Bundle.main.bundlePath.hasSuffix(".app")` first. App bundle processes always run Menu Agent and never route CLI or daemon commands. Non-bundle `daemon` runs `DaemonRuntime`. Non-bundle empty args route to `status`; all other non-bundle invocations route through `CLIRouter`.

Why: macOS AppKit lifecycle is bundle-oriented. The previous model allowed the menu process to become daemon owner and the daemon path to become GUI-capable. Fixed routing removes those states completely.

Alternative considered: keep socket bind outcome as owner arbitration. Rejected because it preserves the ambiguous process role that caused the instability.

### Decision 2: One build artifact, two installed copies

The installer copies the same release Mach-O to `/usr/local/bin/startwatch` and `/Applications/StartWatchMenu.app/Contents/MacOS/startwatch`. `/usr/local/bin/startwatch` is no longer a zsh wrapper and is overwritten unconditionally during install.

Why: `isAppBundle` is only a reliable routing discriminator if CLI invocations do not execute the bundle binary. Two copies keep CLI/LaunchAgent outside the app bundle while preserving one build artifact.

Alternative considered: keep `/usr/local/bin/startwatch` as wrapper into the bundle. Rejected because app-bundle-first routing would turn CLI commands into Menu Agent launches.

### Decision 3: Daemon boundary is behavioral and file-level

The binary may link AppKit because there is one executable target. The rule is that daemon/core runtime files and their transitive objects do not import AppKit or instantiate UI APIs. `TerminalLauncher` is shared by Menu and CLI, but forbidden in DaemonRuntime.

Why: a hard SwiftPM target split is cleaner but increases project and installer complexity. Static boundary checks are sufficient for this stabilization step.

Alternative considered: split into Core/UI library targets now. Deferred as future structural hardening.

### Decision 4: PR1-6 IPC is short-lived raw Codable JSON

Each command opens a Unix socket connection, writes one raw Swift `Codable` enum JSON request, calls `shutdown(SHUT_WR)`, reads one JSON response, and closes. Persistent `subscribe`, `serviceChanged`, and length-prefix framing are explicitly deferred.

Why: the refactor's purpose is runtime role stabilization. Keeping IPC short-lived lowers blast radius while still providing typed responses for terminal handoff and status reads.

Alternative considered: keep current length-prefix/persistent event stream. Rejected for PR1-6 because it expands the refactor into a streaming IPC redesign.

### Decision 5: Daemon owns service lifecycle

Menu and CLI request lifecycle actions over IPC. Daemon starts/restarts background services, returns `executeInTerminal` for interactive services, and performs all stop behavior daemon-side. CLI/Menu never use `ProcessManager` for lifecycle.

Why: daemon is the only writer of runtime lifecycle state. This makes offline behavior consistent and prevents multiple process roles from managing the same service.

Alternative considered: keep CLI local lifecycle fallback for interactive services. Rejected because it violates the client-only role.

### Decision 6: LaunchAgent exit semantics distinguish quit from crash

The LaunchAgent uses `KeepAlive={SuccessfulExit=false}` and `ThrottleInterval=10`. Intentional `.quit` exits with code 0 and remains stopped until kickstarted. Crash/fatal startup errors exit 1 and are restarted by launchd. Duplicate live daemon exits 0.

Why: users need `Stop Daemon` to leave the daemon offline, but unexpected failures should still recover.

Alternative considered: plain `KeepAlive=true`. Rejected because a user-requested quit would immediately restart.

### Decision 7: Installer refreshes LaunchServices best-effort

After replacing `/Applications/StartWatchMenu.app`, the installer runs `lsregister -f /Applications/StartWatchMenu.app` before opening the app. Failure is logged but does not abort installation.

Why: reinstalling a bundle can leave macOS LaunchServices caches pointing at stale bundle metadata or paths. Refreshing the bundle registration makes the app launch path deterministic without turning LaunchServices cache repair into a hard installer dependency.

Alternative considered: rely on `open -na` and LaunchServices to notice the replaced bundle. Rejected because it preserves the cache-staleness class of menu visibility failures.

### Decision 8: IPC clients use bounded timeouts

IPC clients apply a 3-second connect timeout and a 5-second response timeout. Connect failures/timeouts report daemon-offline. Successful connect with missing response before timeout reports daemon-unresponsive and closes the connection.

Why: a missing daemon and a wedged daemon require different user guidance. Bounded IPC prevents CLI and Menu actions from hanging indefinitely when a daemon accepts or exposes a socket but stops responding.

Alternative considered: use blocking socket calls without explicit deadlines. Rejected because daemon hangs would become client hangs.

## Risks / Trade-offs

- [Risk] Static AppKit boundary checks can miss indirect imports or clever aliases.  
  Mitigation: use tokenized grep checks now, document limitations, and track SwiftPM target split as future hardening.

- [Risk] Removing length-prefix framing and subscribe can regress existing menu live updates.  
  Mitigation: PR1-6 menu polling intervals are explicit, with immediate refresh after actions; Stage III restores push.

- [Risk] Two installed binary copies can drift if installer is bypassed.  
  Mitigation: `doctor` validates binary/app/LaunchAgent paths, and docs state installer is the synchronization authority.

- [Risk] `stopService` fallback may kill the wrong external process for process-pattern checks.  
  Mitigation: prefer explicit `stop` command, then managed PID, then port discovery, then process pattern; document best-effort behavior.

- [Risk] `/Applications` install and `/usr/local/bin` copy may require sudo.  
  Mitigation: keep `install.sh` as the full privileged installer and keep `startwatch install` limited to LaunchAgent repair.

## Migration Plan

1. Add docs/specs and tests for routing, IPC, installer, service lifecycle, and boundary rules.
2. Change installer to write real Mach-O to `/usr/local/bin/startwatch`, replace `/Applications/StartWatchMenu.app`, sign bundle, and write new LaunchAgent.
3. Refactor entrypoint to fixed launch-context routing and remove `StartupPlanner`, `showMenu`, `--no-menu`, and local/remote menu role branches.
4. Rename/refocus daemon coordinator to headless `DaemonRuntime`; retain stale socket recovery and bind error exit semantics.
5. Replace active IPC command path with raw short-lived request/response and update CLI/Menu to use it.
6. Move lifecycle commands through daemon-owned IPC; update CLI `stop`, `quit`, `restart all/failed`, and terminal handoff.
7. Add menu polling/offline behavior and validation visibility for skipped terminal autostart.
8. Update architecture, IPC, installer, migration, troubleshooting, and project notes.
9. Run `swift test`, `zsh -n install.sh`, plist parse checks, and AppKit boundary checks.

Rollback strategy: reinstall the previous release using the old installer. Because IPC compatibility is intentionally breaking, mixed old/new daemon-menu-cli processes are unsupported; installer should stop old daemon/menu processes before replacing artifacts.

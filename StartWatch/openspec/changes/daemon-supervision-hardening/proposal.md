
## Why

After `refactor-v2`, StartWatch can distinguish daemon-offline from daemon-unresponsive because IPC clients use bounded timeouts. One narrow failure mode remains: the daemon process can stay alive under launchd while no longer answering IPC, so `KeepAlive={SuccessfulExit=false}` does not restart it and a normal quit request cannot reliably reach `exit(0)`.

## What Changes

- Add a daemon-unresponsive state that is used when IPC connection succeeds or the daemon appears alive but `getStatus` does not answer within timeout.
- Add a menu item `Force Stop Daemon`, visible only while the daemon is unresponsive.
- Add `startwatch quit --force` with the same escalation path as the menu force-stop action.
- Define force-stop escalation: send quit over IPC, wait 3 seconds, send `SIGTERM` through `launchctl kill` to `gui/<uid>/com.user.startwatch`, wait 5 seconds, then send `SIGKILL`.
- Rely on existing stale socket recovery and launchd restart behavior after forced termination.
- Extend `startwatch doctor` to verify daemon responsiveness with `getStatus` timeout and recommend Force Stop when the daemon is unresponsive.
- Add structured force-stop events: `quit_completed_gracefully`, `quit_timeout`, `sigterm_sent`, `sigkill_sent`, `force_stop_pid_replaced`, `force_stop_recovered`, `force_stop_no_recovery`, and `force_stop_recovery_interrupted`.
- Keep daemon-internal watchdogs and separate supervisor processes out of scope.

## Capabilities

### New Capabilities

- `daemon-supervision-hardening`: Forced daemon stop and recovery behavior for the unresponsive-but-still-running daemon case, including menu, CLI, doctor, launchctl escalation, and recovery logging.

### Modified Capabilities

- `typed-short-lived-ipc`: Use daemon-unresponsive timeout results as the trigger for force-stop affordances and doctor guidance.
- `clean-process-exit`: Extend daemon quit behavior with an explicit forced path when graceful IPC quit times out.
- `launchagent-daemon-lifecycle`: Define launchctl signal escalation for the canonical `com.user.startwatch` LaunchAgent and expected restart recovery after forced termination.
- `adaptive-menu-polling`: Add daemon-unresponsive UI state handling and show `Force Stop Daemon` only in that state.
- `service-lifecycle-logging`: Add structured daemon supervision events for quit timeout, signal escalation, and recovery.
- `runtime-installation-contract`: Add canonical LaunchAgent PID discovery and liveness checks used by doctor and force-stop recovery.

## Impact

- Affected code: menu daemon-state model, menu actions, CLI `quit` command parsing, shared force-stop utility, doctor checks, IPC timeout plumbing, and structured logging.
- Affected runtime systems: Unix socket IPC, LaunchAgent `com.user.startwatch`, stale socket recovery, and launchd restart behavior.
- Affected tests: menu state/action visibility, `quit --force` escalation order, doctor recommendation for unresponsive daemon, signal fallback behavior, and structured log event emission.
- Dependencies: requires `refactor-v2` baseline behavior for IPC client timeouts, stale socket recovery, `KeepAlive={SuccessfulExit=false}`, and canonical LaunchAgent label `com.user.startwatch`.

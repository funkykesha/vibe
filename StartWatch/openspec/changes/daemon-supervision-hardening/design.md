
## Context

`refactor-v2` makes process roles deterministic and gives IPC clients bounded connect/response timeouts. That fixes the common client hang, but not the supervisory gap where launchd still sees a daemon process while clients cannot get a `getStatus` response. In that state `KeepAlive={SuccessfulExit=false}` does not restart the daemon, and graceful `quit` may never reach daemon shutdown.

The hardening layer must treat daemon responsiveness as a first-class runtime state, not just infer health from socket presence. It also must avoid killing the wrong process during races with graceful quit, launchd restarts, `ThrottleInterval=10`, and LaunchAgent bootout/uninstall states.

## Goals / Non-Goals

**Goals:**

- Classify daemon state as responsive, unresponsive, or offline using both IPC and process/LaunchAgent evidence.
- Provide one force-stop implementation shared by menu `Force Stop Daemon` and `startwatch quit --force`.
- Preserve graceful quit as the first step; `--force` permits escalation only if graceful quit does not complete.
- Escalate predictably: quit IPC, 3-second wait, `SIGTERM`, 5-second wait, `SIGKILL`.
- Re-check target process identity before each signal so a late graceful quit does not cause a signal to hit a replacement daemon.
- Fall back to direct `kill(pid, signal)` when `launchctl kill gui/<uid>/com.user.startwatch` is unavailable or the LaunchAgent is booted out.
- Define post-signal recovery as a restarted daemon answering `getStatus`, not merely process death or respawn.
- Make `doctor` fail loudly and actionably when daemon is unresponsive.

**Non-Goals:**

- Add daemon-internal watchdogs, heartbeat files, self-restart behavior, or a separate supervisor process.
- Change `refactor-v2` IPC wire format, socket path, or LaunchAgent label.
- Make force stop available for normal offline state with no daemon PID.
- Treat force stop as a service lifecycle action; it supervises only the StartWatch daemon.

## Decisions

### Decision 1: Classify daemon state with IPC first, process evidence second

Daemon state classification uses `getStatus` as the health check:

- `responsive`: IPC `getStatus` returns within timeout.
- `unresponsive`: IPC connect succeeds but `getStatus` response times out.
- `unresponsive`: IPC connect fails, but `launchctl print gui/<uid>/com.user.startwatch` reports a live PID for the daemon.
- `offline`: IPC connect fails and no live daemon PID is found.
- `offline`: `launchctl print` fails, times out, or cannot be parsed, so no live PID is trusted.

Why: socket presence alone misses the case where the daemon is alive but never completed socket setup, and process presence alone misses a daemon that is live but wedged after accepting IPC.

Alternative considered: map all connect failures to offline as in the basic IPC client. Rejected because it hides the "process alive without usable socket" failure that this change exists to recover.

### Decision 2: Capture and verify target PID before every destructive step

Force stop captures the target daemon PID before escalation when a PID is available. After the 3-second graceful wait, it re-checks that the same PID is still alive before sending `SIGTERM`. After the 5-second SIGTERM wait, it re-checks again before sending `SIGKILL`.

If the original PID has exited, force stop stops signaling. If no signal was sent, a successful graceful quit skips recovery verification. If launchd already spawned a different PID, the new PID is not signaled as part of the old escalation.

Why: a daemon can process `quit` near the 3-second boundary. Without PID re-checks, the client could signal a launchd-managed replacement rather than the wedged process it intended to stop.

Alternative considered: signal the LaunchAgent label after fixed sleeps without PID checks. Rejected because label-based signals are convenient but too broad during restart races.

### Decision 3: Prefer launchctl signals, fall back to direct PID signals

When the LaunchAgent is bootstrapped, force stop sends `launchctl kill SIGTERM gui/<uid>/com.user.startwatch` and later `launchctl kill SIGKILL ...`. If `launchctl kill` fails because the job is booted out or unavailable, and the captured daemon PID is still alive, force stop sends `kill(pid, SIGTERM)` or `kill(pid, SIGKILL)` directly.

Why: `launchctl kill` is the right API for launchd-managed jobs, but it is not guaranteed to work after uninstall/bootout. Direct PID fallback preserves recovery for a live process that launchd no longer manages.

Alternative considered: only support launchctl. Rejected because it fails exactly when launchd bookkeeping and process reality diverge.

### Decision 4: `quit --force` means graceful first, escalation allowed

`startwatch quit --force` always starts with normal graceful quit over IPC when possible. If the daemon exits or becomes responsive before the 3-second grace period ends, no signal escalation occurs. If graceful quit times out and the target PID remains alive, escalation proceeds.

When a force-enabled quit completes during the graceful window, the system verifies the original daemon PID is no longer alive with `kill(pid, 0)`, emits `quit_completed_gracefully`, skips recovery verification, and does not emit `quit_timeout`, `sigterm_sent`, `sigkill_sent`, `force_stop_recovered`, or `force_stop_no_recovery`.

Why: users should be able to run one recovery command without first proving the daemon is wedged, but force mode should not skip the clean shutdown path.

Alternative considered: reject `--force` when daemon is responsive. Rejected because state can change between diagnosis and action, and the first graceful step is already safe.

### Decision 5: Recovery requires a responsive restarted daemon

`force_stop_recovered` is emitted only when force stop sent at least one signal and a post-escalation daemon answers `getStatus`. Recovery verification is skipped when force-enabled quit completed gracefully without signal escalation. The recovery wait is at least 13 seconds as an upper-bound wait budget: LaunchAgent `ThrottleInterval=10` plus the 3-second IPC connect timeout. Recovery may complete sooner when `getStatus` succeeds earlier. If no daemon answers within that window after a signal was sent, force stop emits `force_stop_no_recovery`.

If the CLI is interrupted during post-signal recovery verification, force stop emits `force_stop_recovery_interrupted`, sends no rollback or additional signals, and prints unknown-recovery guidance to run `startwatch doctor`.

Why: process death alone does not help the user if launchd does not restart the daemon or the restarted daemon is still unresponsive. Waiting less than the throttle interval would create false recovery failures.

Alternative considered: emit recovery when the old PID dies. Rejected because that measures termination, not restored service.

### Decision 6: Menu force-stop is a latched operation

`Force Stop Daemon` is visible only when daemon state is unresponsive. Once the user starts force stop, the menu enters a force-stop-in-progress state and keeps the operation latched until it completes, recovers, or fails. A mid-operation polling transition does not hide/cancel the escalation; successful responsiveness stops escalation through the coordinator's checks.

Why: disappearing actions mid-escalation make the UI unpredictable. The coordinator, not menu polling, owns operation completion.

Alternative considered: hide the item immediately when the next poll is responsive. Rejected because it couples UI visibility to a multi-step destructive workflow.

### Decision 7: Doctor reports unresponsive daemon as a failing check

`startwatch doctor` performs a bounded `getStatus` health check. If the daemon is unresponsive, doctor exits non-zero and prints an actionable line:

```text
daemon unresponsive (PID 12345). Run 'startwatch quit --force' to recover.

```

If no PID exists and IPC cannot connect, doctor reports daemon offline instead of recommending force stop.

Why: doctor is a diagnostic command, so an unresponsive daemon should be an explicit failure with the exact recovery command.

Alternative considered: warn but exit zero. Rejected because automation and support workflows need non-zero status for a broken daemon.

### Decision 8: Runtime installation contract owns PID discovery

The implementation needs a small LaunchAgent/process inspection helper for `com.user.startwatch`. It parses `launchctl print gui/<uid>/com.user.startwatch` for PID where available, validates liveness with `kill(pid, 0)`, and exposes whether launchctl signal delivery is possible. This should be specified under `runtime-installation-contract` because it depends on canonical label and launchd bootstrap state, not IPC.

Why: force-stop and doctor need one source of truth for "managed daemon PID" and "bootstrapped job can receive launchctl kill".

Alternative considered: duplicate process probing in CLI, menu, and doctor. Rejected because inconsistent PID parsing would create unsafe signal behavior.

## Risks / Trade-offs

- [Risk] `launchctl print` output format can vary across macOS versions.
  Mitigation: keep parsing narrow, validate PID with `kill(pid, 0)`, and fall back to offline/unavailable rather than guessing.

- [Risk] Direct PID fallback can signal an unrelated process if PID identity is stale.  
  Mitigation: use direct kill only for the captured PID, re-check liveness immediately before signaling, and do not retarget new PIDs during the same escalation.

- [Risk] macOS can theoretically reuse a numeric PID between checks.  
  Mitigation: accept numeric PID plus `kill(pid, 0)` as sufficient for this dev tool, because force-stop waits are short and launchd restart should normally allocate a new PID.

- [Risk] Post-signal recovery check may take longer than users expect because launchd throttles restart.  
  Mitigation: menu shows force-stop-in-progress state; CLI prints step progress and waits at least 13 seconds before declaring no recovery.

- [Risk] Menu polling may classify state differently while force stop is running.
  Mitigation: force-stop operation state overrides ordinary menu item visibility until completion.

- [Risk] `force_stop_no_recovery` may still be transient if launchd delays beyond expected throttle.
  Mitigation: message should tell user to run `startwatch doctor` again or inspect LaunchAgent state; do not loop indefinitely.

## Migration Plan

1. Add specs for daemon state classification, force-stop escalation, doctor behavior, menu visibility, recovery logging, and runtime PID discovery.
2. Introduce shared daemon supervision helper for state classification, LaunchAgent PID lookup, signal delivery, and recovery wait.
3. Wire `startwatch quit --force` through the helper while preserving normal `startwatch quit` behavior.
4. Add menu unresponsive state and latched `Force Stop Daemon` action.
5. Extend doctor with bounded `getStatus`, PID-aware unresponsive reporting, non-zero exit, and recovery hint.
6. Add structured events: `quit_completed_gracefully`, `quit_timeout`, `sigterm_sent`, `sigkill_sent`, `force_stop_pid_replaced`, `force_stop_recovered`, `force_stop_no_recovery`, and `force_stop_recovery_interrupted`.
7. Verify with unit tests around state classification, escalation ordering, PID race handling, launchctl fallback, menu visibility, doctor output, and log emission.

Rollback strategy: remove the menu force-stop item and CLI `--force` flag. Existing graceful `quit`, LaunchAgent restart semantics, IPC timeouts, and stale socket recovery from `refactor-v2` remain unchanged.

## Open Questions

- None currently. The design assumes `refactor-v2` has already established canonical LaunchAgent label `com.user.startwatch`, IPC timeouts, stale socket recovery, and `ThrottleInterval=10`.

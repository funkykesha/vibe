
## 1. Runtime Inspection Foundation

- [ ] 1.1 Add a shared runtime inspection helper for canonical LaunchAgent label `com.user.startwatch`.
- [ ] 1.2 Parse `launchctl print gui/<uid>/com.user.startwatch` for daemon PID and validate liveness with `kill(pid, 0)`.
- [ ] 1.3 Treat launchctl failure, timeout, unparsable output, and dead PID as "no live PID found".
- [ ] 1.4 Expose `launchctl kill` availability as true only when `launchctl print gui/<uid>/com.user.startwatch` succeeds for the canonical job; treat booted-out/unavailable jobs as unavailable.
- [ ] 1.5 Add tests for PID parsing, dead PID handling, parse failure fallback, and launchctl signal availability.

## 2. Daemon Health Classification

- [ ] 2.1 Add daemon health states for responsive, unresponsive, and offline.
- [ ] 2.2 Classify responsive when `getStatus` returns within IPC timeout.
- [ ] 2.3 Classify unresponsive when IPC connects but `getStatus` response times out.
- [ ] 2.4 Classify unresponsive when IPC connect fails but runtime inspection finds a live daemon PID.
- [ ] 2.5 Classify offline when IPC connect fails and no live daemon PID is found.
- [ ] 2.6 Add tests for each classification branch, including launchctl parse failure as offline.

## 3. Shared Force-Stop Coordinator

- [ ] 3.1 Implement a shared force-stop coordinator used by CLI and Menu.
- [ ] 3.2 Start force-stop with normal quit IPC when IPC is available.
- [ ] 3.3 Wait 3 seconds for graceful completion by checking that original daemon PID is no longer alive via `kill(pid, 0)`.
- [ ] 3.4 Emit `quit_completed_gracefully` and skip recovery verification when graceful completion is verified without signals.
- [ ] 3.5 Emit `quit_timeout` only when the original daemon PID remains alive after the graceful wait.
- [ ] 3.6 Re-check the same captured numeric PID before each destructive signal.
- [ ] 3.7 Prefer `launchctl kill SIGTERM gui/<uid>/com.user.startwatch`, falling back to `kill(pid, SIGTERM)` only when launchctl signal delivery is unavailable or `launchctl kill` fails and the captured PID remains live.
- [ ] 3.8 Wait 5 seconds after SIGTERM, then send SIGKILL only if the same captured PID remains alive.
- [ ] 3.9 Do not retarget a new daemon PID that appears during escalation; emit `force_stop_pid_replaced` when PID replacement is detected.
- [ ] 3.10 Run recovery verification only after at least one signal was sent.
- [ ] 3.11 Wait at least 13 seconds for a post-signal daemon to answer `getStatus`, ending earlier on success.
- [ ] 3.12 Emit `force_stop_recovered` on post-signal recovery and `force_stop_no_recovery` when recovery deadline expires.
- [ ] 3.13 Handle CLI interruption during recovery wait by emitting `force_stop_recovery_interrupted`, sending no rollback or additional signals, printing unknown-recovery guidance, and telling the user to run `startwatch doctor`.
- [ ] 3.14 Add coordinator tests for graceful success, timeout, SIGTERM path, SIGKILL path, direct PID fallback, PID replacement, recovery success, recovery failure, and interrupted recovery.

## 4. CLI And Doctor Integration

- [ ] 4.1 Add `startwatch quit --force` parsing and route it through the shared force-stop coordinator.
- [ ] 4.2 Keep normal `startwatch quit` behavior unchanged: graceful IPC only, no SIGTERM or SIGKILL.
- [ ] 4.3 Report daemon offline for `quit --force` when no live daemon PID exists, with no signal escalation.
- [ ] 4.4 Print deterministic force-stop progress lines for `quit sent`, `waiting 3s for PID <pid> to exit`, `SIGTERM sent to PID <pid> via <method>`, `waiting 5s`, `SIGKILL sent to PID <pid> via <method>`, and `waiting for daemon recovery`.
- [ ] 4.5 Update `startwatch doctor` to run bounded `getStatus` health classification.
- [ ] 4.6 Make doctor exit non-zero and print `daemon unresponsive (PID <pid>). Run 'startwatch quit --force' to recover.` when daemon is unresponsive.
- [ ] 4.7 Keep doctor offline guidance separate from unresponsive guidance and do not recommend force stop when no live daemon PID exists.
- [ ] 4.8 Add CLI and doctor tests for responsive, unresponsive-with-PID, unresponsive-response-timeout, offline, and `quit --force` cases.

## 5. Menu Integration

- [ ] 5.1 Add menu daemon state for unresponsive and force-stop-in-progress.
- [ ] 5.2 Show `Force Stop Daemon` only when daemon health classification is unresponsive.
- [ ] 5.3 Hide `Force Stop Daemon` for responsive and offline states.
- [ ] 5.4 Wire `Force Stop Daemon` to the shared force-stop coordinator.
- [ ] 5.5 Latch force-stop-in-progress after click and prevent duplicate force-stop actions.
- [ ] 5.6 Keep the coordinator running when polling state changes mid-operation.
- [ ] 5.7 Exit force-stop-in-progress on force-enabled graceful quit completion without escalation, post-signal recovery, recovery failure, or unknown recovery.
- [ ] 5.8 Add menu tests for visibility, latching, duplicate prevention, mid-operation polling, graceful completion exit, recovery success, and no-recovery state.

## 6. Logging And Observability

- [ ] 6.1 Log `quit_completed_gracefully` with daemon PID when known.
- [ ] 6.2 Log `quit_timeout` with target PID and timeout seconds.
- [ ] 6.3 Log `sigterm_sent` and `sigkill_sent` with target PID and signal delivery method.
- [ ] 6.4 Log `force_stop_pid_replaced` when escalation stops because a different daemon PID appears.
- [ ] 6.5 Log `force_stop_recovered` with recovered daemon PID when known.
- [ ] 6.6 Log `force_stop_no_recovery` with recovery deadline seconds.
- [ ] 6.7 Log `force_stop_recovery_interrupted` when CLI recovery wait is interrupted.
- [ ] 6.8 Ensure signal-sent and recovery-failure events are not emitted for graceful completion without escalation.
- [ ] 6.9 Add logging tests for all force-stop event branches.

## 7. Documentation

- [ ] 7.1 Create or update `docs/TROUBLESHOOTING.md` with `startwatch quit --force`, doctor unresponsive output, recovery wait behavior, and when to use Force Stop.
- [ ] 7.2 Update `docs/architecture.md` with daemon supervision states and the shared force-stop coordinator boundary.
- [ ] 7.3 Create or update `docs/MIGRATION.md` or the current release-notes file with the new `startwatch quit --force` CLI flag and menu `Force Stop Daemon` behavior.

## 8. Verification And Cleanup

- [ ] 8.1 Remove generated metadata files from the change tree before commit, including `openspec/changes/daemon-supervision-hardening/specs/.DS_Store`.
- [ ] 8.2 Add a repository ignore rule for `.DS_Store` so future OpenSpec changes do not pick up macOS metadata.
- [ ] 8.3 Run `openspec validate daemon-supervision-hardening --strict`.
- [ ] 8.4 Run `swift test`.
- [ ] 8.5 Run targeted CLI/menu/doctor tests for daemon health and force-stop behavior, including progress-output assertions.
- [ ] 8.6 Run `git diff --check`.


## Context

Daemon cleanup during shutdown is incomplete. The `shutdown()` method stops components (scheduler, file watcher, IPC server) but doesn't properly terminate the process. Current implementation has multiple issues:

1. **Timer references lost**: `Timer.scheduledTimer` in `start()` creates repeating timer for menu agent spawn (every 30s), but no reference stored to cancel it
2. **Dispatch operations continue**: `DispatchQueue.main.asyncAfter` operations (15s initial check, 3s service control delays) execute even after shutdown starts
3. **Process doesn't exit**: No explicit `exit(0)` call. `RunLoop.main.run(until: Date())` does nothing. `CFRunLoopStop()` might not execute if control doesn't reach it
4. **launchd respawning**: Process termination ambiguity allows launchd to respawn daemon, causing "restart" behavior users see

## Goals / Non-Goals

**Goals:**
- Ensure daemon process terminates cleanly with explicit `exit(0)` call
- Cancel all scheduled timers before exit
- Cancel pending dispatch queue operations
- Verify resource cleanup order (services → scheduler → dispatch queue → timers → exit)
- Log DAEMON_SHUTDOWN_COMPLETE after all cleanup, before exit

**Non-Goals:**
- Don't redesign the CheckScheduler or service lifecycle
- Don't change start() behavior (only add references needed for shutdown)
- Don't add new monitoring or tracking features

## Decisions

### 1. Timer Reference Management
**Decision:** Store repeating timer reference in DaemonCoordinator as property, cancel in shutdown()

**Rationale:** `Timer.scheduledTimer(withTimeInterval:repeats:block:)` has no returned token to cancel later. Store reference to keep it alive and explicitly invalidate during shutdown.

**Alternative considered:** Try to cancel via CFRunLoopTimerInvalidate (requires CFRunLoop access) — invasive and risky

### 2. Dispatch Queue Cancellation Strategy
**Decision:** Capture DispatchWorkItem for all asyncAfter operations, store in array, cancel during shutdown

**Rationale:** DispatchWorkItem.cancel() stops pending operations before they execute. Prevents orphan checks/service restarts during shutdown.

**Alternative considered:** Accept they'll run (race condition) — leaves system in inconsistent state

### 3. Process Exit Timing
**Decision:** Call `exit(0)` after all resources released, immediately after logging DAEMON_SHUTDOWN_COMPLETE

**Rationale:** Ensures daemon actually terminates. No ambiguity. launchd sees exit code 0 (clean shutdown) vs crash.

**Alternative considered:** Return from shutdown() and let main() call exit — requires coordination, error-prone

### 4. Resource Cleanup Order
**Decision:** Stop in sequence: services → scheduler → file watcher → dispatch queue → cancel timers → log complete → exit

**Rationale:** Services first (graceful stop). Scheduler next (no new checks). IPC server next (no new commands). File watcher next (cleanup filesystem resources). Dispatch queue and timers last (no queued operations). Exit last.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| **Timer invalidate race**: Repeating timer fires while shutdown runs | Store strong reference, invalidate immediately in shutdown |
| **Dispatch operations still queued**: asyncAfter jobs in queue execute after exit() | Capture DispatchWorkItem, call .cancel() before exit |
| **Lost logs during exit**: DAEMON_SHUTDOWN_COMPLETE log never written if exit() is async | Make Logger synchronous for shutdown logs or add small delay before exit(0) |
| **launchd respawn loop**: Process exits cleanly but launchd restarts it immediately | Not in scope of this fix. Operator should use `launchctl unload` if intentional shutdown needed. Process will exit cleanly now. |

## Migration Plan

1. Modify `start()`: Capture Timer and DispatchWorkItem references
2. Modify `shutdown()`: Cancel timers and dispatch operations before exit
3. Verify build succeeds
4. Manual test: Click quit, verify no respawn after 30+ seconds

## Open Questions

1. Should we add a flag to prevent respawn (like "shutdown-requested" that prevents ipcServer handler from respawning)? Answer: Not needed if process exits cleanly.
2. Do we need timeout on shutdown (max 5s wait, then force exit)? Answer: No — clean teardown is fast, no indefinite waits.

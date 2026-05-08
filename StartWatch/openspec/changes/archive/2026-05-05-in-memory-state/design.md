## Context

StartWatch currently writes service state to disk on each check cycle and reads the same file on short polling intervals for UI updates. This causes steady-state disk I/O on the hot path and introduces avoidable encode/decode overhead. The approved direction is to keep runtime state in RAM and use disk only as periodic persistence backup.

This design must align with the event-driven IPC model from `bidirectional-unix-socket`, where daemon state changes are pushed to subscribers. It also must preserve restart behavior by restoring from the latest valid snapshot.

Constraints:
- Keep behavior graceful when daemon restarts or exits unexpectedly.
- Limit data-loss window to the configured flush interval.
- Preserve compatibility for commands that require last-known state even when daemon is not actively checking services.

## Goals / Non-Goals

**Goals:**
- Make in-memory state the single runtime source of truth for daemon checks and IPC publishing.
- Replace per-cycle disk writes with periodic checkpoint flushes plus shutdown flush.
- Restore startup state from the last valid checkpoint and publish that snapshot through IPC.
- Reduce steady-state file operations and remove disk dependency from normal read path.

**Non-Goals:**
- No new external storage backend (SQLite/DB) in this change.
- No guarantee of zero data loss on hard crash between flushes.
- No redesign of service check scheduling cadence itself.

## Decisions

1. Introduce explicit in-memory state store in daemon lifecycle
- Decision: `StateManager` owns mutable service state in RAM, with atomic snapshot read API for consumers (checker, IPC broadcaster, CLI status path).
- Why: central ownership removes duplicated read/write logic and prevents divergence between disk and live state.
- Alternative considered: keep file as source of truth and add in-memory cache. Rejected because it still keeps disk on hot path and adds coherence complexity.

2. Write-through removed; checkpoint-based persistence added
- Decision: replace "write on every cycle" with periodic flush timer (default `300s`) and forced flush on clean shutdown.
- Why: reduces I/O while preserving restart persistence.
- Rationale:
  - StartWatch monitors developer services, not production transactional state.
  - Worst-case loss after abrupt termination (`kill -9`) is up to 5 minutes; services are re-checked on the normal cycle anyway.
  - With 10 services and 30s checks, batching around 100 state updates between flushes is acceptable.
  - Interval stays configurable in `startwatch.yml` for users who need tighter persistence.
- Alternative considered: flush only on state change. Rejected because noisy changes could still spike writes and no bounded persistence cadence.

3. Crash-safe checkpoint format and commit strategy
- Decision: write checkpoint to temp file then atomic rename to `last_check.json`.
- Why: prevents partial-file corruption after interruption and keeps last valid snapshot intact.
- Alternative considered: direct overwrite. Rejected due to corruption risk on crash/power loss.

4. Startup restore pipeline publishes restored snapshot
- Decision: daemon boot loads latest valid checkpoint into memory before first check cycle, then exposes snapshot to IPC subscribers (`statusSnapshot`) immediately.
- Why: gives menu/CLI immediate last-known state and consistent startup propagation.
- Alternative considered: wait for first live check before publishing state. Rejected because it causes cold-start gaps.

5. IPC integration reads only memory during runtime
- Decision: IPC `getStatus` and push events use in-memory snapshot/diffs; disk is never read on poll/tick path.
- Why: aligns with RAM source-of-truth and removes decode overhead from recurring operations.
- Alternative considered: periodic disk reconciliation. Rejected as unnecessary once single in-memory authority exists.

6. Flush trigger policy
- Decision: three triggers:
  - interval flush (e.g., every N seconds),
  - graceful shutdown flush,
  - optional immediate flush on critical lifecycle transitions (daemon stop requested, major config reload).
- Why: balances durability vs I/O while keeping bounded loss window.
- Alternative considered: shutdown-only flush. Rejected due to large potential data-loss window.

7. In-memory state structure
- Decision: `StateManager` stores:
  - `services: [String: ServiceStatus]` keyed by service name,
  - `lastCheckTime: Date?` as timestamp of last completed check cycle,
  - `generation: UInt64` monotonic counter incremented on every mutation.
- Why `generation`:
  - enables cheap "changed since last flush?" check (`lastFlushedGeneration != generation`),
  - avoids race-prone boolean dirty-flag semantics during rapid mutation sequences.
- Alternative considered: `isDirty` boolean. Rejected because it can miss set-clear-set style transitions under concurrent flows.

8. Concurrency model
- Decision: `StateManager` uses a concurrent `DispatchQueue` with barrier writes.
  - reads (`get`, snapshot): synchronous reads on concurrent queue,
  - writes (`update`): barrier sync/async on same queue,
  - flush: capture consistent snapshot under queue protection, perform disk I/O outside queue.
- Why:
  - keeps synchronous call sites simple in checker and IPC handling paths,
  - supports concurrent reads under client fan-out,
  - isolates mutation ordering without full async refactor.
- Alternative considered: Swift actor. Rejected because it forces async propagation through many currently synchronous call sites.
- Alternative considered: `NSLock`. Rejected because it serializes readers and writers equally; read concurrency matters for frequent status requests.

9. CLI offline fallback reads checkpoint file
- Decision: when daemon socket unavailable, CLI `status` reads `last_check.json` directly and prints staleness indicator.
- Why: preserves useful diagnostics in daemon-offline mode without restoring steady-state polling.
- Constraint: this is the only runtime disk-read path and is error-recovery only, not hot-path state transport.

10. Checkpoint schema versioning
- Decision: checkpoint JSON includes explicit schema version from first release.
- Format:
  ```json
  {
    "version": 1,
    "timestamp": "2025-01-15T10:30:00Z",
    "services": []
  }
  ```
- Why: provides forward-compatible restore migrations and avoids silent parse ambiguity when shape evolves.

## Risks / Trade-offs

- [Crash between flushes loses recent state] -> Keep interval bounded, document expected loss window, allow interval tuning.
- [Flush timer contention with check cycle] -> Serialize writes through single persistence queue and coalesce concurrent flush requests.
- [Malformed checkpoint blocks restore] -> Validate decode; on failure, start with empty/default state and emit warning.
- [Migration mismatch with legacy polling paths] -> Remove live polling reads in menu-agent only after IPC in-memory path is verified.
- [State drift in concurrent access] -> Provide immutable snapshot reads and single writer semantics in state manager.
- [Unbounded state growth if services change dynamically] -> Keep state keyed strictly by config-defined services; prune removed services on next check cycle; do not retain history in memory.

## Migration Plan

1. Implement in-memory state ownership API and update checker to write RAM only.
2. Add checkpoint writer with temp-file + atomic rename.
3. Add startup restore loader with validation and fallback path.
4. Wire IPC snapshot/event publishing from in-memory state.
5. Remove remaining runtime disk-read paths for live updates.
6. Add tests:
   - restore from valid checkpoint,
   - corrupted checkpoint fallback,
   - flush cadence + shutdown flush,
   - no live disk reads during steady-state IPC flows.
7. Rollout strategy:
   - gated by tests and `swift test` pass,
   - monitor logs for restore/flush errors in first runs.
8. Rollback:
   - revert to previous write-each-cycle path if severe persistence regressions detected.

## Dependencies

### Hard dependency on Stage III (`bidirectional-unix-socket`)
- Decision 5 (IPC read/push fully from memory) requires bidirectional socket subscribe/push infrastructure.
- Migration step 4 (wire IPC snapshot/event publishing from memory) depends on Stage III broadcast and subscriber lifecycle.

### Can be implemented independently from Stage III
- Decisions 1-3 and 7-8,10 (RAM store, checkpoint writer, atomic rename, in-memory model, concurrency model, schema versioning).
- Migration steps 1-3 (state API, checkpoint flush, startup restore).

### Delivery implication
- Steps 1-3 can ship as intermediate PR while Stage III still in progress.
- Steps 4-5 should merge only after Stage III IPC path is available.

## Open Questions

- Should restore warnings surface in menu UI or remain daemon logs only?
  - Recommendation: daemon logs only. Menu-agent receives valid snapshot (possibly empty) through IPC; exposing restore internals in UI adds complexity with low user actionability.

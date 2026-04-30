## Context

### Current State

The `server.js` file starts an Express server that:
1. Initializes the Eliza client
2. Fetches models from `/v1/models` endpoint
3. Probes all models in parallel to check availability
4. Displays real-time progress via `StartupDisplayManager`
5. Continues running indefinitely after probe completes

The server currently runs indefinitely, requiring manual Ctrl+C to exit.

### Problem

For quick validation or CI/CD scenarios, the terminal stays open after probe completes, requiring manual intervention to close it. This is inefficient for scripts that just need to check model availability.

### Constraints

- Must preserve default behavior (server stays running) for normal use
- Auto-exit should be opt-in via command-line flag
- Should not interfere with normal server operation
- Exit code should indicate success/failure

## Goals / Non-Goals

**Goals:**
- Add `--exit-after-probe` flag to trigger automatic exit after probe completes
- Wait for all probe requests to complete before exiting
- Exit with code 0 for successful startup, 1 for errors
- Log final probe results before exiting

**Non-Goals:**
- Changing default behavior (server still runs normally without flag)
- Implementing timeout for probe
- Adding complex exit conditions
- Changing the probe logic itself

## Decisions

### Decision 1: Use command-line flag `--exit-after-probe`

**Rationale:** Opt-in approach preserves backward compatibility. Users who want auto-exit explicitly request it.

**Alternatives considered:**
- **Option A (chosen):** Command-line flag `--exit-after-probe`
  - Pros: Explicit, backward compatible, easy to discover
  - Cons: Requires flag to be specified

- **Option B:** Environment variable `EXIT_AFTER_PROBE=true`
  - Pros: Can be set in scripts easily
  - Cons: Less discoverable, mixes config with flags

- **Option C:** Default auto-exit with `--keep-running` flag
  - Pros: Simplifies CI/CD use cases
  - Cons: Breaking change, harder for interactive use

### Decision 2: Track probe completion via counter

**Rationale:** The current code tracks models probed by counting with `displayManager.totalModelCount` and `displayManager.completedCount`. We can use these to determine when probing is complete.

**Implementation:** Check when `completedCount === totalModelCount` or all models have probe status set.

### Decision 3: Exit on probe completion, not server.ready

**Rationale:** The probe completes independently of HTTP server readiness. Users want to exit after seeing probe results, not after HTTP server is ready to accept requests.

**Implementation:** Monitor `onModelUpdate` events and exit when all models have final status.

## Risks / Trade-offs

### Risk 1: Server exits while still initializing
**Mitigation:** Wait for all probe events to complete before checking for exit criteria

### Risk 2: Race condition with HTTP requests
**Mitigation:** Exit only after probe is complete, which happens before HTTP server is fully operational

### Risk 3: Exit fires too early in case of errors
**Mitigation:** Exit with code 1 on any startup errors, exit with code 0 only on successful probe completion

## Migration Plan

### Deployment Steps

1. Add `--exit-after-probe` flag parsing to server.js
2. Add global flag `shouldExitAfterProbe`
3. Track probe completion status
4. When probe complete and flag is set:
   - Log final summary
   - Exit with code 0
5. Test with flag enabled and disabled

### Rollback Strategy

- Single file change (server.js) — easy to revert
- No breaking changes — flag is opt-in
- Git history preserved

## Open Questions

None - implementation is straightforward.

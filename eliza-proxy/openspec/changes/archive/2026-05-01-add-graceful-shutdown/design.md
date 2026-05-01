## Context

### Current State

The auto-exit-after-probe feature uses `process.exit(0)` which immediately terminates the Node.js process without allowing the Express server to gracefully close active connections.

Current exit logic:
```javascript
setTimeout(() => {
  console.log('\nProbe complete. Exiting due to --exit-after-probe flag.');
  process.exit(0);  // Abrupt termination
}, 100);
```

### Problem

Calling `process.exit(0)` causes:
- Active HTTP connections to be dropped abruptly
- In-flight requests to error on the client side
- Potential resource leaks (connections, file handles, etc.)
- No opportunity for cleanup callbacks to run
- Poor user experience when clients get connection reset errors

### Why Graceful Shutdown Matters

For a proxy service that terminates after validation:
- In-flight requests should complete before exit
- Clients should receive proper responses
- Resources should be cleaned up correctly
- Exit should be orderly, not abrupt

### Constraints

- Must preserve existing `--exit-after-probe` functionality
- Must handle case where server never started listening (startup error)
- Minimal code changes - focused on graceful shutdown
- No external dependencies for graceful shutdown
- Must work with Express's built-in `server.close()` API

## Goals / Non-Goals

**Goals:**
- Add graceful shutdown to close HTTP connections before exiting
- Handle case where server is not listening (no graceful close needed)
- Export server object for access in exit callback
- Use async/await for `server.close()` operation

**Non-Goals:**
- Changing exit timing or delay
- Adding new CLI options
- Implementing advanced graceful shutdown (signal handling, timeout enforcement)
- Changing external API or behavior
- Complex shutdown coordination with other resources

## Decisions

### Decision 1: Export Server Object

**Rationale:** The server object from `app.listen()` is needed in the exit callback to call `server.close()`.

**Implementation:**
```javascript
// Currently:
app.listen(PORT, () => { ... });

// Change to:
const server = app.listen(PORT, () => { ... });
```

**Scope:** Server variable is now accessible in the exit callback's closure scope.

**Alternatives considered:**
- **Option A (chosen):** Export `server` to module-level variable
  - Pros: Simple, direct access, no refactoring needed
  - Cons: Adds module-level variable
  - **Chosen:** Most straightforward for this use case

- **Option B:** Wrap exit logic in function with server parameter
  - Pros: Encapsulated, testable
  - Cons: Requires passing server reference, more complex call chain
  - **Rejected:** Over-engineering for this simple case

- **Option C:** Emit custom event on server and listen for exit trigger
  - Pros: Decoupled, event-driven
  - Cons: Complex, multiple event listeners, harder to follow flow
  - **Rejected:** Too much complexity

### Decision 2: Async Exit Callback

**Rationale:** `server.close()` returns a Promise and is async. The callback must be async to `await` the close operation.

**Implementation:**
```javascript
// Currently:
setTimeout(() => {
  console.log('\nProbe complete. Exiting...');
  process.exit(0);
}, FINAL_DISPLAY_DELAY_MS);

// Change to:
setTimeout(async () => {
  console.log('\nProbe complete. Exiting...');
  if (server.listening) {
    await server.close();
  }
  process.exit(0);
}, FINAL_DISPLAY_DELAY_MS);
```

**Alternatives considered:**
- **Option A (chosen):** `async () => {}` with `await server.close()`
  - Pros: Modern async/await syntax, clear flow, clean error handling
  - Cons: Requires async callback
  - **Chosen:** Best practice for Promise operations

- **Option B:** Promise.then() syntax
  - Pros: Works without async callback
  - Cons: Nested callbacks, less readable, harder to add cleanup steps
  - **Rejected:** Older pattern, less maintainable

### Decision 3: Check server.listening

**Rationale:** If the server never started listening (e.g., crash during startup or port in use), calling `server.close()` would be redundant or error-prone. Only close if already listening.

**Implementation:**
```javascript
if (server.listening) {
  await server.close();
}
```

**Alternatives considered:**
- **Option A (chosen):** Check `server.listening` property
  - Pros: Simple boolean check, Express built-in
  - Cons: Property may not be available in all Node versions
  - **Chosen:** Most straightforward, Express documents this property

- **Option B:** Try/catch around `server.close()`
  - Pros: Handles all cases
  - Cons: Less explicit, may hide other errors
  - **Rejected:** Less clear intent

- **Option C:** Always call `server.close()` without check
  - Pros: No check needed
  - Cons: May cause errors if server not listening
  - **Rejected:** Risk of unexpected errors

## Risks / Trade-offs

### Risk 1: server.listening Property Not Available

**Risk:** The `server.listening` property may not exist in older Express or Node.js versions.

**Mitigation:**
- Express 4.x+ (used here) supports `server.listening`
- Node.js 8+ (used here) supports http.Server.listening
- If property missing, `if (server.listening)` evaluates to `falsy` (safe)

### Risk 2: Slow Exit Due to Connections

**Risk:** If clients have long-lived connections, awaiting `server.close()` may delay exit significantly.

**Mitigation:**
- Express's `server.close()` stops accepting new connections immediately
- Existing connections have time to complete (typically <30s for HTTP requests)
- If long-running connections are a concern, add timeout (future enhancement)
- For this proxy service, connections are typically short-lived HTTP requests

### Risk 3: Module-level Variable Scope

**Risk:** Exporting `server` to module-level variable increases global state, which can be problematic for testing.

**Mitigation:**
- Variable is scoped to server.js module only
- Not exported (not in module.exports)
- Only used internally for graceful shutdown
- Minimal impact on testability

### Risk 4: server.close() Failure

**Risk:** If `server.close()` rejects (unlikely), the Promise rejection would cause unhandled rejection warning but exit still happens after `process.exit(0)`.

**Mitigation:**
- `server.close()` rarely fails (Express is mature)
- If it does fail, `process.exit(0)` still terminates process
- Could add try/catch for completeness (optional)
- Current implementation acceptable for this use case

### Trade-off: Simplicity vs Robustness

**Trade-off:** We're choosing a simple graceful shutdown approach rather than a comprehensive one.

**Justification:**
- For a validation script that exits after probes, simple graceful shutdown is sufficient
- More complex features would be over-engineering:
  - Connection timeouts
  - Signal handling (SIGTERM, SIGINT)
  - Healthcheck endpoint for draining
  - Multiple-phase shutdown
- Future can add complexity if needed

## Migration Plan

### Deployment Steps

1. Export server object from `app.listen()` call (line ~280)
2. Change exit setTimeout callback to async (line ~70)
3. Add `server.listening` check and `await server.close()` (lines ~74-77)
4. Verify normal exit behavior still works
5. Test with in-flight HTTP request to verify graceful handling

### Rollback Strategy

- Straightforward revert: remove `server.close()` logic, revert to `process.exit(0)`
- Single file modification - easy to restore
- No breaking changes - rollback unlikely needed

## Open Questions

None - the implementation is clearly defined and straightforward.

## Test Strategy

- **Normal case:** Server exits after probes complete (existing test, still passes)
- **Error case:** Server exits cleanly if startup error occurred (no graceful close)
- **Graceful shutdown:** Simulate in-flight HTTP request, verify it completes before exit (new)
- **Backward compatibility:** CLI flag behavior unchanged (existing test)

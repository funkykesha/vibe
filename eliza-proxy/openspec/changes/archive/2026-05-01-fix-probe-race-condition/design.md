## Context

### Current State

The auto-exit-after-probe feature (recently implemented) has a race condition:

1. **Initialization**: `totalModels` is set in the async callback when models are fetched from the API (line ~204)
2. **Probes**: Model probes run in parallel and complete asynchronously via `onModelUpdate` callbacks
3. **Race**: If a probe completes BEFORE `totalModels` is set, the condition `completedProbeCount === totalModels` evaluates incorrectly and the exit never triggers

### Why This Happens

The code currently does:
```javascript
if (shouldExitAfterProbe && completedProbeCount === totalModels) {
  // exit logic
}
```

But `totalModels` may still be `undefined` or `0` if probes complete quickly before the async fetch completes.

### Constraints

- Must fix the race condition without changing the feature's external behavior
- Cannot add delays or slow down probe execution
- Minimal code changes - this is a focused bug fix
- Must maintain backward compatibility with existing CLI flag behavior

## Goals / Non-Goals

**Goals:**
- Eliminate race condition in probe completion tracking
- Ensure reliable exit behavior regardless of timing
- Add minimal code changes (single flag + guard)

**Non-Goals:**
- Changing the exit timing or delay
- Refactoring the probe architecture
- Adding new CLI options
- Changing external API behavior

## Decisions

### Decision 1: Add `modelsLoaded` Flag

**Rationale:** A boolean flag is the simplest solution to track when `totalModels` has been initialized. The flag acts as a guard, preventing premature exit checks.

**Implementation:**
```javascript
let modelsLoaded = false;  // Track when totalModels is set

// In async callback where models are fetched:
totalModels = calculatedTotalCount;
modelsLoaded = true;  // Set flag after assigning

// In onModelUpdate:
if (shouldExitAfterProbe && modelsLoaded && completedProbeCount === totalModels) {
  // exit logic
}
```

**Alternatives considered:**
- **Option A (chosen):** Boolean `modelsLoaded` flag
  - Pros: Simple, clear, minimal overhead, no complex logic
  - Cons: Adds one variable

- **Option B:** Use Promise.all to await both fetch and probes
  - Pros: More explicit coordination
  - Cons: Major refactoring required, would break current async architecture
  - **Rejected:** Too much code change for a simple race condition fix

- **Option C:** Poll for `totalModels` to be set
  - Pros: No flag variable
  - Cons: Wastes CPU cycles, complex logic, less elegant
  - **Rejected:** Over-engineered solution

### Decision 2: Initialize Variables Clearly

**Rationale:** Initialize `totalModels = 0` explicitly (currently implicit undefined) to make the race condition more obvious in code and prevent accidental truthy comparisons.

**Implementation:**
```javascript
let totalModels = 0;  // Will be set after models fetch completes
let completedProbeCount = 0;
let modelsLoaded = false;
```

## Risks / Trade-offs

### Risk 1: Flag Forgetting to Set

**Risk:** The `modelsLoaded` flag might not be set in all code paths, causing the exit to never trigger.

**Mitigation:**
- Set flag immediately after `totalModels` assignment
- Add test case for race condition timing
- Keep the two assignments adjacent in code for visibility

### Risk 2: Edge Case with Zero Models

**Risk:** If zero models are returned from the API, `totalModels = 0` and `modelsLoaded = true`. If no probes fire, the exit might not trigger.

**Mitigation:**
- This is already handled by the current logic - zero probes means `completedProbeCount = 0`
- The condition `0 === 0` with `modelsLoaded = true` will correctly exit
- This is actually the desired behavior for zero models (exit immediately after confirming no models to probe)

### Trade-off: Minimal Changes vs Robust Solution

**Trade-off:** We're choosing minimal code additions (one flag) over more robust coordination patterns.

**Justification:**
- The race condition is timing-dependent and unlikely in normal usage
- Boolean flag is sufficient to eliminate the race
- More complex solutions would require refactoring probe architecture
- Minimal changes reduce risk of introducing new bugs

## Migration Plan

### Deployment Steps

1. Add `modelsLoaded` flag after variable declarations (line ~34)
2. Update `onModelUpdate` exit condition to check `modelsLoaded` flag (line ~68)
3. Set `modelsLoaded = true` after `totalModels` assignment in async callback (line ~204)
4. Add test case for race condition timing (fast probe before initialized)
5. Verify normal exit behavior still works

### Rollback Strategy

- Single file change with simple logic - easy to revert
- No breaking changes - rollback unlikely needed
- Git history preserved

## Open Questions

None - the fix is straightforward and clearly defined by the user's recommendation.

## Test Strategy

- **Normal case:** Server exits after all probes complete (existing test)
- **Race condition test:** Fast probes complete before `totalModels` initialized (new)
- **Edge case:** Zero models returned (verify exit behavior)
- **Backward compatibility:** Server without flag still runs indefinitely (existing behavior)

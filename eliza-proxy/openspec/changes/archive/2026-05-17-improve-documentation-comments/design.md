## Context

### Current State

The `auto-exit-after-probe` feature was recently implemented in `server.js` (lines 17-73). The implementation adds a command-line flag `--exit-after-probe` that causes the server to automatically exit after all models have been probed.

Current implementation includes:
- CLI flag parsing at top of file
- Global variable tracking exit flag state
- Probe completion counter and total models tracker
- Exit logic in `onModelUpdate` callback
- 100ms setTimeout delay before exit

### Problem

Recent code review identified several documentation issues:
1. No comments explaining the `--exit-after-probe` flag or its purpose
2. No comments explaining the probe completion tracking mechanism
3. Magic number `100` (timeout delay) without explanation
4. No edge case handling documented (e.g., zero models)

This makes it harder for future maintainers to understand:
- Why the feature exists (CI/CD use case)
- How the tracking logic works (completed vs total count comparison)
- Why 100ms delay was chosen
- What happens in edge cases

### Constraints

- Must preserve existing functionality - only add comments
- Changes should be minimal and focused on readability
- Comment style should match project conventions (if any exist)
- Must not introduce new code behavior or break existing tests

## Goals / Non-Goals

**Goals:**
- Add inline comments explaining the `--exit-after-probe` flag
- Add comments explaining the probe completion tracking logic
- Replace magic number `100` with named constant
- Document edge case handling (zero models, race conditions)

**Non-Goals:**
- Changing the feature's behavior
- Refactoring the implementation
- Adding new functionality
- Changing variable names
- Adding extensive external documentation (this is code-level comments only)

## Decisions

### Decision 1: Add Named Constant for Timeout Delay

**Rationale:** Replace magic number `100` with `const FINAL_DISPLAY_DELAY_MS` to make purpose explicit and easier to adjust.

**Implementation:**
```javascript
// Time to wait after final model completes before exiting (ms)
// Allows final display to render and message to be shown
const FINAL_DISPLAY_DELAY_MS = 100;
```

**Alternatives considered:**
- **Option A (chosen):** Named constant `FINAL_DISPLAY_DELAY_MS`
  - Pros: Self-documenting, easy to modify, follows common best practices
  - Cons: Adds one constant to module scope

- **Option B:** Leave as magic number `100`
  - Pros: Simpler, one fewer line
  - Cons: Unclear purpose, harder to adjust, less maintainable

### Decision 2: Add Inline Comments for Key Logic

**Rationale:** Add concise, clear comments explaining the purpose of each code block without being verbose.

**Implementation locations:**
1. CLI flag parsing section
2. Global variables declaration
3. Probe completion tracking in `onModelUpdate` callback
4. Edge case handling (if added)

**Comment style:** Single-line, concise, explain "why" rather than "what"

### Decision 3: Add TODO/FIXME Comments for Known Issues

**Rationale:** Document the race condition identified in code review so future maintainers are aware.

**Implementation:**
```javascript
// Track total number of models to probe (set after models loaded from API)
let totalModels = 0;
let modelsLoaded = false;  // TODO: Add flag to prevent race condition when probes complete before totalModels is set
```

## Risks / Trade-offs

### Risk 1: Over-commenting

**Risk:** Adding too many comments can make the code harder to read by increasing cognitive load.

**Mitigation:** Keep comments concise and focus on the "why" rather than restating what the code already says. Target ~5-10 lines of comments total.

### Risk 2: Comment Drift

**Risk:** Comments may become outdated if code changes but comments don't.

**Mitigation:** Place comments near the logic they explain, making it easier to update both together during maintenance.

### Risk 3: Adding TODO Without Fix May Create Technical Debt

**Risk:** Adding TODO comment for race condition without actually fixing it may create debt.

**Mitigation:** The race condition is edge-case (timing dependent) and unlikely to manifest in typical usage. Documenting it makes future maintainers aware without blocking the documentation improvement. Consider opening separate issue for the fix if needed.

## Migration Plan

### Deployment Steps

1. Add constant `FINAL_DISPLAY_DELAY_MS` after variable declarations (line ~15)
2. Add comment explaining `--exit-after-probe` flag (line ~18)
3. Add comment explaining probe tracking variables (lines ~33-34)
4. Add comment in `onModelUpdate` callback explaining tracking logic (lines ~63-75)
5. Replace `100` with `FINAL_DISPLAY_DELAY_MS` (line ~72)
6. (Optional) Add `modelsLoaded` flag if implementing fix
7. Run tests to ensure behavior unchanged

### Rollback Strategy

- Single file change with comments only - easy to revert
- No functional changes - rollback unlikely needed
- Git history preserved

## Open Questions

None - the changes are straightforward documentation improvements. All implementation details are clear from the code review feedback.

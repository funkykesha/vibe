## Why

Recent code review of the auto-exit-after-probe feature identified that the implementation lacks inline documentation comments explaining the feature's purpose. This reduces maintainability and makes it harder for future developers to understand the reasoning behind specific implementation decisions.

## What Changes

- Add docstring/inline comments explaining the `--exit-after-probe` flag and its purpose
- Add comments explaining the probe completion tracking logic
- Replace magic number `100` with a named constant for clarity
- Add edge case handling comments

**BREAKING**: None - documentation-only changes

## Capabilities

### Modified Capabilities
- `auto-exit-after-probe`: Add inline documentation and improve code maintainability

## Impact

**Affected Code:**
- `server.js` - Add comments explaining CLI flag parsing, probe completion tracking, and exit logic

**Affected APIs:**
- None - CLI interface unchanged, only comments added

**Behavioral Changes:**
- None - functionality unchanged, only code readability improved

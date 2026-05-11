## Why

Verification of `refactor-v2` found one spec/implementation mismatch around legacy `--no-menu` handling and a fragile final verification gate where aggregate `swift test` may hang in this environment. This follow-up change aligns runtime behavior with spec intent and makes verification execution deterministic.

## What Changes

- Enforce explicit handling for legacy `--no-menu` on `startwatch daemon`:
  - either reject with non-zero and clear error, or
  - update spec scenario to match supported behavior (no silent ambiguity).
- Add a stable verification runner for OpenSpec/CI checks used in `8.7`.
- Document and test the chosen legacy-flag behavior and verification runner contract.

## Capabilities

### New Capabilities
- `verification-runner-stability`: defines deterministic verification execution for refactor-v2 checks (suite-based runner, required sub-checks, and pass/fail contract).

### Modified Capabilities
- `headless-daemon-mode`: clarify/implement the legacy `--no-menu` scenario so runtime behavior and requirement wording are consistent.

## Impact

- Affected code: daemon command argument handling, verify scripts/tools, and tests.
- Affected docs/specs: headless daemon behavior and verification workflow documentation.
- No external dependencies expected.

## Context

`refactor-v2` passed strict OpenSpec validation and task completion, but verify found one behavior/spec mismatch: legacy `--no-menu` after `startwatch daemon` is currently ignored instead of explicitly rejected. In parallel, aggregate `swift test` can intermittently hang in this environment, while suite-by-suite execution is stable.

## Goals / Non-Goals

**Goals:**
- Make daemon CLI argument handling explicit for deprecated `--no-menu`.
- Eliminate silent acceptance of unsupported legacy daemon flags.
- Define a deterministic verification runner contract for OpenSpec/CI checks.
- Add tests and docs for both behavior and verification flow.

**Non-Goals:**
- No new runtime modes or role arbitration redesign.
- No reintroduction of menu ownership logic into daemon runtime.
- No change to typed short-lived IPC contract.

## Decisions

1. Legacy `--no-menu` is rejected in daemon mode.
- Rationale: current silent-ignore behavior is ambiguous and failed verification intent.
- Behavior: `startwatch daemon --no-menu` exits non-zero with `unknown flag: --no-menu`.
- Alternatives considered:
  - Keep ignoring flag and modify spec: rejected because it preserves ambiguous user feedback.
  - Accept flag as no-op: rejected because it suggests supported behavior.

2. Keep launch-context routing as-is.
- Rationale: `refactor-v2` already moved role selection to launch context and removed showMenu branches; no further routing complexity is needed.

3. Verification runner contract uses deterministic suite-by-suite test execution.
- Rationale: full aggregate `swift test` may hang in this environment; filtered suite execution is stable and reproducible.
- Contract includes required checks: targeted test suites, `zsh -n install.sh`, plist lint, boundary script, docs presence/format checks.
- Alternatives considered:
  - Require only aggregate `swift test`: rejected due to flakiness in current env.

## Risks / Trade-offs

- [Risk] Some users/scripts still pass `--no-menu` and will now fail fast.
  - Mitigation: provide clear error and migration note (`startwatch daemon` without legacy flag).
- [Risk] Suite list can drift when tests are renamed.
  - Mitigation: keep runner script/test list in-repo and update with test changes.
- [Risk] Environment-specific behavior may differ from CI host.
  - Mitigation: document runner as deterministic fallback and prefer aggregate test where stable.

## Migration Plan

1. Implement daemon argument validation and error path for `--no-menu`.
2. Add/adjust routing and daemon command tests for legacy flag rejection.
3. Add verification runner artifact/script and docs updates.
4. Run verification contract checks and update OpenSpec tasks.

## Open Questions

- Should unknown daemon flags (besides `--no-menu`) also fail-fast uniformly now, or only explicitly deprecated ones in this change?

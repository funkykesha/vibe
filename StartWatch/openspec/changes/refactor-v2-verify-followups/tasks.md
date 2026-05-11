## 1. Daemon Legacy Flag Contract

- [ ] 1.1 Add explicit daemon-args validation for deprecated `--no-menu` and return non-zero with `unknown flag: --no-menu`.
- [ ] 1.2 Keep `startwatch daemon` behavior unchanged for valid invocation (headless runtime start).
- [ ] 1.3 Add/adjust tests for daemon legacy-flag rejection and normal daemon invocation.

## 2. Deterministic Verification Runner

- [ ] 2.1 Add a repository verification runner command/script that executes approved suite-by-suite test flow with strict fail-fast behavior.
- [ ] 2.2 Include required non-test checks in runner: `zsh -n install.sh`, plist lint, boundary check.
- [ ] 2.3 Add/adjust tests (or command-level checks) validating runner contract and expected failure behavior.

## 3. Documentation Alignment

- [ ] 3.1 Update verification/maintenance docs with deterministic runner usage and fallback rules versus aggregate `swift test`.
- [ ] 3.2 Update migration/troubleshooting notes for deprecated `--no-menu` rejection behavior.

## 4. End-to-End Validation

- [ ] 4.1 Run deterministic verification runner and capture pass results.
- [ ] 4.2 Run `openspec verify`/`openspec validate --strict` for the new change artifacts and ensure they are apply-ready.

## ADDED Requirements

### Requirement: Verification runner SHALL execute deterministic suite-based checks
The project SHALL provide a deterministic verification runner for refactor-v2 style completion checks that does not rely exclusively on aggregate `swift test` execution.

#### Scenario: Suite-based test execution
- **WHEN** verification runner executes
- **THEN** it runs the approved test suites one-by-one with explicit pass/fail handling
- **AND** it exits non-zero if any suite fails

#### Scenario: Required non-test checks
- **WHEN** verification runner executes
- **THEN** it runs `zsh -n install.sh`, plist lint, and daemon boundary check
- **AND** it exits non-zero when any required check fails

### Requirement: Verification runner contract SHALL be documented
The project SHALL document the deterministic verification flow and when it is used as fallback to aggregate `swift test`.

#### Scenario: Documentation is present
- **WHEN** contributors read verification docs
- **THEN** they can run the same deterministic verification command set locally
- **AND** they can understand when suite-based execution is preferred over aggregate run

## ADDED Requirements

### Requirement: ServiceChecker has no data races
`ServiceChecker` SHALL compile without warnings under Swift 6 strict concurrency checking. The `resumed` bool pattern used in `checkPort` and `checkCommand` SHALL be replaced with a thread-safe mechanism.

#### Scenario: Port check completes without race
- **WHEN** `checkPort` is called and port is open
- **THEN** continuation resumes exactly once from whichever path fires first (ready state or timeout), with no concurrent mutation

#### Scenario: Command check timeout fires
- **WHEN** `checkCommand` is called and command exceeds timeout
- **THEN** process is terminated and continuation resumes exactly once, no double-resume possible

#### Scenario: Swift 6 build is warning-free
- **WHEN** project builds with `SWIFT_STRICT_CONCURRENCY = complete`
- **THEN** zero Sendable or actor isolation warnings in `ServiceChecker.swift`

### Requirement: AsyncHelpers semaphore bridge is safe
`runSync` in `Core/AsyncHelpers.swift` SHALL not cause actor deadlocks when called from the main thread. It SHALL be documented with a comment if usage is restricted to CLI-only (non-AppKit) context.

#### Scenario: CLI command runs sync helper
- **WHEN** `StatusCommand.run()` calls `runSync { await ... }` from the main thread
- **THEN** async work completes and result is returned without deadlock

## ADDED Requirements

### Requirement: Runtime SHALL discover canonical daemon PID safely
The runtime SHALL provide a shared helper that discovers the daemon PID for canonical LaunchAgent label `com.user.startwatch` and validates liveness before the PID is used for doctor or force-stop decisions.

#### Scenario: LaunchAgent reports live PID

- **WHEN** `launchctl print gui/<uid>/com.user.startwatch` reports a daemon PID and `kill(pid, 0)` succeeds
- **THEN** runtime reports that PID as live

#### Scenario: LaunchAgent reports dead PID

- **WHEN** `launchctl print gui/<uid>/com.user.startwatch` reports a daemon PID but `kill(pid, 0)` fails
- **THEN** runtime treats live PID as not found

#### Scenario: LaunchAgent print fails

- **WHEN** `launchctl print gui/<uid>/com.user.startwatch` exits non-zero, times out, or returns unparsable output
- **THEN** runtime treats live PID as not found
- **AND** runtime does not guess from stale output

### Requirement: Runtime SHALL expose launchctl signal availability
The runtime SHALL tell force-stop whether canonical LaunchAgent signal delivery is available before force-stop falls back to direct PID signals.

#### Scenario: Bootstrapped LaunchAgent can receive launchctl kill

- **WHEN** canonical LaunchAgent job is bootstrapped and `launchctl print` succeeds
- **THEN** runtime reports launchctl signal delivery as available

#### Scenario: Booted-out LaunchAgent cannot receive launchctl kill

- **WHEN** canonical LaunchAgent job is booted out or unavailable
- **THEN** runtime reports launchctl signal delivery as unavailable

#### Scenario: Direct PID fallback stays constrained

- **WHEN** launchctl signal delivery is unavailable but captured daemon PID remains alive
- **THEN** runtime allows direct signal only to that captured PID

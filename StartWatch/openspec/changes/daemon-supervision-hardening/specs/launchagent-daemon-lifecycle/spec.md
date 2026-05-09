## ADDED Requirements

### Requirement: Force stop SHALL signal canonical LaunchAgent when available
Force stop SHALL prefer `launchctl kill` against `gui/<uid>/com.user.startwatch` when the LaunchAgent job is bootstrapped and a matching target PID remains alive.

#### Scenario: SIGTERM through launchctl

- **WHEN** daemon remains alive after graceful quit timeout and LaunchAgent job is bootstrapped
- **THEN** force stop sends `launchctl kill SIGTERM gui/<uid>/com.user.startwatch`

#### Scenario: SIGKILL through launchctl

- **WHEN** daemon remains alive 5 seconds after `SIGTERM` and LaunchAgent job is bootstrapped
- **THEN** force stop sends `launchctl kill SIGKILL gui/<uid>/com.user.startwatch`

### Requirement: Force stop SHALL fall back to direct PID signal when launchctl kill is unavailable
Force stop SHALL use direct `kill(pid, signal)` only for the captured live daemon PID when `launchctl kill` cannot signal the canonical LaunchAgent job.

#### Scenario: LaunchAgent booted out

- **WHEN** LaunchAgent job is booted out but the captured daemon PID remains alive
- **THEN** force stop sends `kill(pid, SIGTERM)` instead of failing recovery

#### Scenario: launchctl kill fails before SIGKILL

- **WHEN** captured daemon PID remains alive after SIGTERM wait and `launchctl kill SIGKILL` fails
- **THEN** force stop sends `kill(pid, SIGKILL)` to the captured PID

#### Scenario: No live captured PID

- **WHEN** launchctl kill is unavailable and no captured daemon PID remains alive
- **THEN** force stop does not send a direct signal
- **AND** force stop runs recovery verification only if an earlier signal was sent

### Requirement: Forced termination SHALL rely on LaunchAgent restart policy
After forced daemon termination, restart behavior SHALL be governed by LaunchAgent `KeepAlive={SuccessfulExit=false}` and `ThrottleInterval=10`.

#### Scenario: SIGKILL restart is throttled

- **WHEN** force stop terminates daemon abnormally
- **THEN** launchd MAY restart daemon subject to `ThrottleInterval=10`

#### Scenario: Recovery check accounts for throttle

- **WHEN** force stop sent at least one signal and waits for recovered daemon responsiveness
- **THEN** recovery deadline is at least 13 seconds
- **AND** the wait ends earlier if daemon answers `getStatus`

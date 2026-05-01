## ADDED Requirements

### Requirement: Menu polling adapts to startup state
System SHALL poll cache at 0.5s interval when any service has `isStarting: true`, and at default 3s interval otherwise.

#### Scenario: Fast polling during startup
- **WHEN** menu agent reads cache and finds entry with `isStarting: true`
- **THEN** system schedules poll timer at 0.5s

#### Scenario: Slow polling after all services resolved
- **WHEN** menu agent reads cache and all entries have `isStarting: false`
- **THEN** system schedules poll timer at 3s

#### Scenario: Transition from fast to slow polling
- **WHEN** last `starting` service finalizes to running
- **THEN** system cancels 0.5s timer, schedules new 3s repeating timer

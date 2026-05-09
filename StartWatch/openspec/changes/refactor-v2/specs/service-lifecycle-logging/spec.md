## ADDED Requirements

### Requirement: Log skipped terminal autostart
Daemon SHALL log a structured event when a service has `autostart=true` and `background!=true`, because daemon cannot open terminals.

#### Scenario: Non-background autostart skipped
- **WHEN** daemon loads a service with `autostart=true` and `background!=true`
- **THEN** daemon skips autostart
- **AND** logs an event with service name and reason `requires background=true`

### Requirement: Log service stop behavior
Daemon SHALL log service stop attempts, selected stop strategy, and stop outcome.

#### Scenario: Stop command used
- **WHEN** daemon stops a service using explicit `stop` command
- **THEN** daemon logs stop attempt and command strategy

#### Scenario: PID fallback used
- **WHEN** daemon stops a service by discovered PID or port
- **THEN** daemon logs PID strategy and whether SIGKILL escalation was required

#### Scenario: No stoppable target
- **WHEN** daemon cannot find a stop command or process target
- **THEN** daemon logs stop error with reason `no stoppable target`

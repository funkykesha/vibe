## ADDED Requirements

### Requirement: Install flow is local-only
The WorkGuard rebuild, install, launch, and autostart flow SHALL NOT transfer WorkGuard activity data, configuration, logs, or secrets off the machine.

#### Scenario: Rebuild does not export data
- **WHEN** the operator runs `bash rebuild.sh`
- **THEN** the system does not upload or transmit WorkGuard activity data, configuration, logs, or secrets

### Requirement: Outbound transfer requires explicit user request
The system MUST NOT send WorkGuard data off-machine unless the user explicitly requests that transfer.

#### Scenario: No implicit outbound behavior
- **WHEN** WorkGuard starts through `/Applications/WorkGuard.app` or the LaunchAgent
- **THEN** the system does not perform implicit telemetry, diagnostics upload, or data export

### Requirement: Secrets never leave the machine during install and launch
The system MUST NOT export secrets from WorkGuard under any install, launch, autostart, or debug path covered by this change.

#### Scenario: WorkGuard starts through supported paths
- **WHEN** WorkGuard starts through `bash rebuild.sh`, `/Applications/WorkGuard.app`, the LaunchAgent, or direct debug Python
- **THEN** secrets remain local to the machine

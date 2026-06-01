## MODIFIED Requirements

### Requirement: Outbound transfer requires explicit user request
The system MUST NOT send data off-machine unless the user explicitly requests that transfer. A user who enables the Todoist engagement reminder and configures a Todoist API token thereby explicitly requests outbound calls limited to the Todoist API endpoint; no other WorkGuard data is transmitted.

#### Scenario: No implicit outbound behavior
- **WHEN** WorkGuard starts through `/Applications/WorkGuard.app` or the LaunchAgent with default configuration
- **THEN** the system does not perform implicit telemetry, diagnostics upload, or data export

#### Scenario: Configured Todoist call is the explicit request
- **WHEN** the user has enabled the reminder and set a Todoist API token
- **THEN** the system MAY query the Todoist API endpoint using that token
- **THEN** no WorkGuard activity data, configuration, logs, or other secrets are sent in or alongside that request

### Requirement: Secrets never leave the machine during install and launch
The system MUST NOT export secrets from WorkGuard under any install, launch, autostart, or debug path, except that a user-configured third-party API token from local environment MAY be sent only to its own third-party endpoint as the authentication for the user's explicitly enabled integration.

#### Scenario: WorkGuard starts through supported paths
- **WHEN** WorkGuard starts through `bash rebuild.sh`, `/Applications/WorkGuard.app`, the LaunchAgent, or direct debug Python
- **THEN** secrets remain local to the machine

#### Scenario: Todoist token is used only for its own endpoint
- **WHEN** the Todoist integration is enabled and a token is configured
- **THEN** the token is stored locally in a gitignored `.env` file or process environment and is sent only to the Todoist API endpoint
- **THEN** the token is never written to logs or transmitted to any other destination

## ADDED Requirements

### Requirement: Root page displays model probe dashboard
The system SHALL serve a read-only model status dashboard from the root HTTP path.

#### Scenario: Open root dashboard
- **WHEN** a user opens `GET /`
- **THEN** the system returns an HTML page
- **AND** the page displays overall probe state
- **AND** the page displays provider groups and model health statuses

#### Scenario: Dashboard updates while probes run
- **WHEN** probe status is `running`
- **THEN** the dashboard periodically fetches current probe status
- **AND** updates summary counts and model rows without a full page reload

#### Scenario: Dashboard remains useful after probes complete
- **WHEN** probe status is `complete`
- **THEN** the dashboard displays final summary counts
- **AND** the dashboard displays each model's final probe status, kind, latency, and check timestamp when available

### Requirement: HTTP API exposes probe status summary
The system SHALL expose a JSON endpoint that reports current probe state and model health summary.

#### Scenario: Fetch probe status
- **WHEN** a client requests `GET /v1/probe-status`
- **THEN** the response includes `probeStatus` as `idle`, `running`, or `complete`
- **AND** the response includes total counts for `pending`, `success`, `warning`, and `error`
- **AND** the response includes provider-grouped model statuses

#### Scenario: Probe status before model catalog loads
- **WHEN** `GET /v1/probe-status` is requested before models are loaded
- **THEN** the response reports `probeStatus` as `idle`
- **AND** the response includes zero counts
- **AND** the response does not fail

### Requirement: Model catalog includes non-blocking probe metadata
The system SHALL keep catalog models visible while attaching probe metadata when available.

#### Scenario: Fetch models during probe
- **WHEN** a client requests `GET /v1/models` while probes are pending
- **THEN** all catalog models remain present in the response
- **AND** models with known probe state include `probe.status`
- **AND** models without final probe state are treated as selectable pending models

#### Scenario: Fetch models after probe warning
- **WHEN** a model has probe status `warning`
- **THEN** the model remains present in `/v1/models`
- **AND** the model metadata includes probe details such as `kind`, `latencyMs`, and `checkedAt` when available
- **AND** the model is not presented as inactive solely because of the warning

### Requirement: Health endpoint reports probe lifecycle
The system SHALL include probe lifecycle information in the health response.

#### Scenario: Health during background probe
- **WHEN** a client requests `GET /v1/health` while probes are running
- **THEN** the response status remains `ok` if the server is otherwise healthy
- **AND** the response includes `probeStatus: "running"`
- **AND** the response includes probe summary counts

#### Scenario: Health after probe completion
- **WHEN** all model probes have completed
- **THEN** `GET /v1/health` includes `probeStatus: "complete"`
- **AND** the response includes final probe summary counts

## MODIFIED Requirements

### Requirement: HTTP API exposes probe status summary
The system SHALL expose a JSON endpoint that reports current catalog readiness, optional probe state, and model health summary.

#### Scenario: Fetch status without active probe
- **WHEN** a client requests `GET /v1/probe-status` and no explicit probe is running
- **THEN** the response includes `probeStatus` as `idle`
- **AND** the response includes catalog readiness information
- **AND** the response includes provider-grouped model catalog statuses

#### Scenario: Fetch status during explicit probe
- **WHEN** a client requests `GET /v1/probe-status` while explicit probes are running
- **THEN** the response includes `probeStatus` as `running`
- **AND** the response includes total diagnostic counts for `pending`, `success`, `warning`, and `error`
- **AND** the response includes provider-grouped diagnostic model statuses

#### Scenario: Fetch status after explicit probe
- **WHEN** a client requests `GET /v1/probe-status` after explicit probes have completed
- **THEN** the response includes `probeStatus` as `complete`
- **AND** the response includes final diagnostic counts
- **AND** the response keeps catalog availability separate from diagnostic probe outcome

#### Scenario: Status before model catalog loads
- **WHEN** `GET /v1/probe-status` is requested before models are loaded
- **THEN** the response reports `probeStatus` as `idle`
- **AND** the response includes zero counts
- **AND** the response does not fail

### Requirement: Model catalog includes non-blocking probe metadata
The system SHALL keep compatible catalog models visible while attaching observed-health and optional probe metadata when available.

#### Scenario: Fetch models after catalog readiness
- **WHEN** a client requests `GET /v1/models` after the catalog is loaded
- **THEN** compatible catalog models are present in the response
- **AND** unsupported streaming or non-chat models are absent from the selectable model list
- **AND** included models expose compatibility metadata

#### Scenario: Fetch models with observed Monium health
- **WHEN** a model has Monium observed-health facts
- **THEN** `/v1/models` includes observed metadata such as successful status evidence, stream evidence, and observation window
- **AND** model selection does not require a fresh real provider probe

#### Scenario: Fetch models after diagnostic probe warning
- **WHEN** a compatible model has explicit diagnostic probe status `warning`
- **THEN** the model remains present in `/v1/models`
- **AND** the model metadata includes probe details such as `kind`, `latencyMs`, and `checkedAt` when available
- **AND** the model is not presented as inactive solely because of the diagnostic warning

#### Scenario: Fetch models containing preview variants
- **WHEN** a preview model is included by observed catalog policy
- **THEN** `/v1/models` includes `stability: preview`
- **AND** clients can distinguish it from stable models

### Requirement: Health endpoint reports probe lifecycle
The system SHALL include catalog readiness and optional probe lifecycle information in the health response.

#### Scenario: Health after catalog readiness without probe
- **WHEN** a client requests `GET /v1/health` after catalog readiness and no explicit probe is running
- **THEN** the response status remains `ok` if the server is otherwise healthy
- **AND** the response includes `probeStatus: "idle"`
- **AND** the response includes catalog readiness metadata

#### Scenario: Health during explicit background probe
- **WHEN** a client requests `GET /v1/health` while explicit probes are running
- **THEN** the response status remains `ok` if the server is otherwise healthy
- **AND** the response includes `probeStatus: "running"`
- **AND** the response includes diagnostic probe summary counts

#### Scenario: Health after explicit probe completion
- **WHEN** all explicit model probes have completed
- **THEN** `GET /v1/health` includes `probeStatus: "complete"`
- **AND** the response includes final diagnostic probe summary counts

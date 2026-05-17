## ADDED Requirements

### Requirement: Build catalog from serving capabilities
The system SHALL expose only models that are compatible with the proxy's supported chat serving path.

#### Scenario: Streaming model is compatible
- **WHEN** a catalog model has chat capability and supports the proxy's streaming chat route
- **THEN** `/v1/models` includes the model
- **AND** the model metadata includes provider, family, stability, and `capabilities.streaming: true`

#### Scenario: Non-streaming model is incompatible
- **WHEN** a catalog model cannot stream through the proxy's `/v1/chat` route
- **THEN** `/v1/models` does not include the model
- **AND** selecting the model is prevented before `/v1/chat` would fail

#### Scenario: Non-chat model is excluded
- **WHEN** a catalog entry is for embeddings, images, audio, transcription, TTS, realtime, batch-only, or another non-chat capability
- **THEN** `/v1/models` does not include the model

### Requirement: Include observed Monium model facts
The system SHALL be able to enrich catalog models with deterministic observed-health facts from Monium metrics.

#### Scenario: Read observed facts with fixed time range
- **WHEN** the system reads Monium model metrics
- **THEN** it uses absolute UTC `from` and `to` timestamps
- **AND** it does not use relative windows such as `now-1d` as an implicit data source

#### Scenario: Chunk Monium reads
- **WHEN** the system reads `chat.status` metrics for observed models
- **THEN** it chunks requests by bounded selectors such as vendor, status, or stream mode
- **AND** it avoids requesting a response larger than the Monium MCP transport limit

#### Scenario: Extract observed stream support
- **WHEN** Monium returns a successful `chat.status` row for a model with `stream=true`
- **THEN** the observed facts mark that model with `observedStreamTrue: true`
- **AND** the observed facts include the source window used to compute the value

#### Scenario: Ignore zero-traffic rows for freshness
- **WHEN** Monium returns a model row whose aggregate value is zero for the selected window
- **THEN** the system does not treat that row as evidence that the model was recently used

### Requirement: Merge catalog and observed facts deterministically
The system SHALL merge Eliza catalog data, local capability rules, and Monium observed facts using deterministic rules.

#### Scenario: Catalog model has observed facts
- **WHEN** a model exists in the Eliza catalog and has matching Monium observed facts
- **THEN** `/v1/models` includes both catalog metadata and observed-health metadata
- **AND** the response includes the Monium observation window

#### Scenario: Observed model is not in catalog
- **WHEN** Monium contains successful traffic for a model that is absent from the current Eliza catalog
- **THEN** the model is not automatically exposed as selectable
- **AND** the system records or reports the mismatch for diagnostics

#### Scenario: Preview model is observed and compatible
- **WHEN** a preview or experimental model is observed with successful compatible traffic
- **THEN** the model may be included according to preview policy
- **AND** its metadata marks `stability: preview`

#### Scenario: Preview model is not observed
- **WHEN** a preview or experimental model has no successful compatible Monium evidence in the selected window
- **THEN** the default catalog does not include it

### Requirement: Preserve explicit probe diagnostics
The system SHALL keep model probes as an explicit diagnostic operation rather than a default catalog validation step.

#### Scenario: Manual probe requested
- **WHEN** a user calls the explicit probe endpoint or starts the server with explicit probe mode enabled
- **THEN** the system performs real model requests for the requested probe scope
- **AND** the probe response identifies that real provider calls were made

#### Scenario: Default catalog load
- **WHEN** the server starts with default configuration
- **THEN** the system does not send real model completion requests solely to validate the model catalog

#### Scenario: Probe result does not hide compatible model
- **WHEN** a diagnostic probe returns warning or timeout for an otherwise compatible catalog model
- **THEN** the model remains controlled by catalog capability rules
- **AND** the probe result is exposed only as diagnostic metadata

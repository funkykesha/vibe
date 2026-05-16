## MODIFIED Requirements

### Requirement: Server supports auto-exit after model probe completion via command-line flag
The system SHALL provide a `--exit-after-probe` command-line flag that causes the server to automatically shut down after all background model probes complete.

#### Scenario: Start server with --exit-after-probe flag
- **WHEN** server starts with `npm start -- --exit-after-probe`
- **THEN** server starts normally
- **THEN** server probes all models with bounded background concurrency
- **THEN** all probe events are processed
- **THEN** server logs final probe results
- **THEN** server exits with code 0

#### Scenario: Start server without flag - normal operation
- **WHEN** server starts without `--exit-after-probe` flag
- **THEN** server starts accepting HTTP requests while probes run
- **THEN** server continues running after all probes complete
- **THEN** server does NOT exit automatically

#### Scenario: Exit code indicates probe completion
- **WHEN** server exits after probe completes
- **THEN** exit code is 0
- **WHEN** server exits due to startup error
- **THEN** exit code is 1

#### Scenario: Exit waits for all models to complete
- **WHEN** server started with `--exit-after-probe` flag and models are probed with bounded concurrency
- **THEN** server does NOT exit before all models have final probe status
- **THEN** server ensures all pending probe events are processed
- **THEN** server displays final results before exiting

#### Scenario: Auto-exit works with successful, warning, and failed model probes
- **WHEN** models are probed and final states include `success`, `warning`, and `error`
- **THEN** server waits for ALL models to reach final probe state
- **THEN** server displays final counts for all states
- **THEN** server exits with code 0

### Requirement: Exit condition is race-condition free
The system SHALL ensure the exit condition correctly handles probes completing asynchronously before total model state is initialized.

#### Scenario: Probe completes before totalModels is set
- **WHEN** a model probe completes before the async model fetch callback sets total model count
- **THEN** the exit check does NOT trigger prematurely
- **THEN** the system waits until model state is initialized
- **THEN** the exit check only evaluates after model state is initialized
- **THEN** the server correctly exits after ALL probes complete

#### Scenario: Zero models available
- **WHEN** the API returns zero models
- **THEN** total model count is 0
- **THEN** no probes are initiated
- **THEN** probe status becomes complete
- **THEN** server exits with code 0 when `--exit-after-probe` is set

#### Scenario: Background probe prevents premature exit
- **WHEN** probe state is not complete
- **THEN** exit condition does NOT trigger
- **THEN** server continues running until every model has final probe state

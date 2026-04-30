## ADDED Requirements

### Requirement: Server supports auto-exit after model probe completion via command-line flag
The system SHALL provide a `--exit-after-probe` command-line flag that causes the server to automatically shut down after all models have been probed.

#### Scenario: Start server with --exit-after-probe flag
- **WHEN** server starts with `npm start -- --exit-after-probe`
- **THEN** server probes all models normally
- **THEN** all probe events are processed
- **THEN** server logs final probe results
- **THEN** server exits with code 0

#### Scenario: Start server without flag - normal operation
- **WHEN** server starts without `--exit-after-probe` flag
- **THEN** server probes all models
- **THEN** server continues running and accepting HTTP requests
- **THEN** server does NOT exit automatically

#### Scenario: Exit code indicates probe completion
- **WHEN** server exits after probe completes
- **THEN** exit code is 0 (success)
- **WHEN** server exits due to startup error (missing token, etc.)
- **THEN** exit code is 1 (failure)

#### Scenario: Exit waits for all models to complete
- **WHEN** server started with `--exit-after-probe` flag and models are probed in parallel
- **THEN** server does NOT exit before all models have final probe status
- **THEN** server ensures all pending probe events are processed
- **THEN** server displays final results before exiting#### 
Scenario: Auto-exit works with both successful and failed model probes
- **WHEN** models are probed and some succeed while others fail
- **THEN** server waits for ALL models to complete probing
- **THEN** server displays results for successful and failed models
- **THEN** server exits with code 0 (probe completed, regardless of individual model results)

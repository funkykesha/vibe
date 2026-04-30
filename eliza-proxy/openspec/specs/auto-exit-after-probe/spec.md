# auto-exit-after-probe Specification

## Purpose
Provides CLI flag `--exit-after-probe` for automatic server shutdown after all model probes complete. Used for CI/CD, validation scripts, and quick health checks.

## Requirements
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
- **THEN** server displays final results before exiting

#### Scenario: Auto-exit works with both successful and failed model probes
- **WHEN** models are probed and some succeed while others fail
- **THEN** server waits for ALL models to complete probing
- **THEN** server displays results for successful and failed models
- **THEN** server exits with code 0 (probe completed, regardless of individual model results)

### Requirement: Exit condition is race-condition free
The system SHALL ensure the exit condition correctly handles probes completing asynchronously before totalModels is initialized.

#### Scenario: Probe completes before totalModels is set (race condition)
- **WHEN** a model probe completes before the async model fetch callback sets `totalModels`
- **THEN** the exit check does NOT trigger prematurely
- **THEN** the system waits until `modelsLoaded` flag is set
- **THEN** the exit check only evaluates after `modelsLoaded === true`
- **THEN** the server correctly exits after ALL probes complete

#### Scenario: Zero models available
- **WHEN** the API returns zero models
- **THEN** `totalModels = 0` and `modelsLoaded = true`
- **THEN** no probes are initiated
- **THEN** `completedProbeCount = 0`
- **THEN** exit condition `modelsLoaded && completedProbeCount === totalModels` is true (0 === 0)
- **THEN** server exits with code 0

#### Scenario: Flag prevents premature exit
- **WHEN** `modelsLoaded === false` and `completedProbeCount === totalModels`
- **THEN** exit condition does NOT trigger
- **THEN** server continues running until `modelsLoaded` becomes `true`

### Requirement: Server performs graceful shutdown before exiting
The system SHALL close active HTTP connections gracefully before terminating the process when using `--exit-after-probe` flag.

#### Scenario: Graceful shutdown when server is listening
- **WHEN** server exits after probes complete and server is listening for HTTP connections
- **THEN** the server stops accepting new HTTP connections
- **THEN** existing in-flight requests complete before server closes
- **THEN** the server calls `server.close()` to close HTTP server
- **THEN** process exits with code 0 after server is closed

#### Scenario: Exit without graceful shutdown if server never started
- **WHEN** server exits after probes complete but server never started listening (e.g., startup error)
- **THEN** the system skips `server.close()` call
- **THEN** the system exits directly with code 0
- **THEN** no attempts are made to close a non-listening server

#### Scenario: Exit with graceful shutdown for zero models
- **WHEN** API returns zero models and server is listening
- **THEN** the server closes gracefully via `server.close()`
- **THEN** process exits with code 0

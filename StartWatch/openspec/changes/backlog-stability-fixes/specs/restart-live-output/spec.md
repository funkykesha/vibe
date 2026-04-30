## ADDED Requirements

### Requirement: Render live terminal table during `restart all`
System SHALL render an in-place terminal table showing real-time status of service startup when user runs `startwatch restart all`.

#### Scenario: Initial table render with all services starting
- **WHEN** user runs `startwatch restart all` with 3 failed services
- **THEN** system renders 3 rows with ⏳ icons and `starting... 0.0s` timings

#### Scenario: Service finalizes to running
- **WHEN** first service passes its readiness check at 1.2s
- **THEN** system updates that row to ❓ icon with `running 1.2s`, row becomes permanent append

#### Scenario: Service fails to start within timeout
- **WHEN** service fails all checks until `startupTimeout` expires
- **THEN** system updates row to ✗ icon with `failed 10.0s` and failure detail

#### Scenario: Final output after all services resolved
- **WHEN** all services have either succeeded or failed
- **THEN** terminal shows final table with all rows, cursor positioned below table, process exits with code = failed count

### Requirement: Services are spawned in background without blocking
System SHALL spawn service start commands as background processes, not blocking on process completion.

#### Scenario: Spawn three services concurrently
- **WHEN** `restart all` processes 3 failed services
- **THEN** all 3 `Process.start()` calls return immediately without waiting for command completion

#### Scenario: Start command is a long-running server
- **WHEN** service start command is `node server.js` (runs indefinitely)
- **THEN** system spawns it background and proceeds to poll readiness loop

### Requirement: Poll readiness with configurable interval and timeout
System SHALL poll each service's readiness check every 500ms until service passes check or `startupTimeout` expires.

#### Scenario: Service starts quickly
- **WHEN** service is Redis (starts in ~300ms)
- **THEN** system polls at 0s, 0.5s — passes check at 0.5s, exits poll loop after 1 attempt

#### Scenario: Service is slow Postgres with cold start
- **WHEN** service has `startupTimeout: 15` and takes 12s to become ready
- **THEN** system polls at 0s, 0.5s, 1.0s, ... 12.0s — passes check at 12.0s after 24 attempts

#### Scenario: Service never becomes ready
- **WHEN** service never passes readiness check and default timeout (10s) expires
- **THEN** system marks service as failed after 20 poll attempts

### Requirement: Render in-place updates for starting services only
System SHALL use ANSI cursor-up to redraw only `starting` rows; finalized rows are written as permanent appends.

#### Scenario: Terminal table during startup
- **WHEN** 2 services are starting, 1 already finalized to running
- **THEN** system prints finalized running row once (no redraw), redraws 2 starting rows in-place with updated timers

#### Scenario: First service finalizes
- **WHEN** first service passes check at 0.8s
- **THEN** system writes finalized row, redraws remaining starting rows one position lower

### Requirement: Fallback to append-only when not a TTY
System SHALL detect non-TTY output and fall back to append-only rendering (no in-place updates).

#### Scenario: Output piped to file
- **WHEN** user runs `startwatch restart all > output.txt`
- **THEN** all status changes append new lines, no cursor movement codes printed

#### Scenario: Output in GitHub Actions CI
- **WHEN** command runs in CI environment without terminal
- **THEN** system uses append-only mode

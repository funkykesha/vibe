## Purpose
Define how startup state is propagated to clients and persisted across daemon restarts.

## Requirements

### Requirement: CLI writes isStarting state to cache before spawn
System SHALL write `isStarting: true` for each service about to be restarted to `last_check.json` before spawning processes.

#### Scenario: Restart all writes starting state
- **WHEN** user runs `startwatch restart all` for 3 services
- **THEN** system writes `[CodableCheckResult...]` with `isStarting: true` for all 3 services immediately

#### Scenario: Daemon overwrites starting state periodically
- **WHEN** daemon performs next check cycle after CLI wrote `isStarting: true`
- **THEN** daemon overwrites entries with real results (`isRunning: true/false`, `isStarting: false`)

### Requirement: Menu bar reads isStarting from cache and reflects in icon
System SHALL derive startup/transition state for menu rendering from daemon-provided in-memory snapshot/event stream. Periodic file-cache polling SHALL NOT be used for live startup-state propagation. Checkpoint file MAY be used only for daemon-offline fallback paths.

#### Scenario: Menu shows starting state from daemon snapshot
- **WHEN** menu agent subscribes and receives `statusSnapshot` containing a service in starting state
- **THEN** menu bar displays startup indicator based on snapshot without reading cache file on timer

#### Scenario: Menu updates after startup transition
- **WHEN** daemon publishes service transition from starting to running
- **THEN** menu agent updates icon state from push event immediately

### Requirement: Startup state persists across daemon restarts via checkpoints
System SHALL ensure startup-state propagation remains available across restart boundaries by persisting checkpoint snapshots from daemon memory on scheduled and shutdown flushes, instead of requiring per-command direct cache writes on the hot path.

#### Scenario: Startup state survives daemon restart via checkpoint
- **WHEN** daemon had persisted checkpoint and then restarts
- **THEN** restored in-memory snapshot is available for first subscriber snapshot before next check cycle

#### Scenario: No live polling dependency for startup propagation
- **WHEN** runtime startup transitions occur while daemon is healthy
- **THEN** propagation to menu/clients occurs through in-memory state and IPC events, not periodic file reads

#### Scenario: Start command sets starting state in memory
- **WHEN** daemon receives `startService` command via IPC
- **THEN** daemon sets service state to `starting` in memory, increments generation, and broadcasts `serviceChanged` before launching process

### Requirement: CodableCheckResult includes isStarting field
`CodableCheckResult` struct SHALL include `isStarting: Bool` field with default value `false`.

#### Scenario: Decode old cache file without isStarting field
- **WHEN** system reads `last_check.json` from before this change (no `isStarting` key)
- **THEN** Codable decoder defaults `isStarting` to `false`, old files decode successfully

#### Scenario: Encode new cache file with isStarting
- **WHEN** system writes new cache entries after restart
- **THEN** JSON includes `"isStarting": true/false` field

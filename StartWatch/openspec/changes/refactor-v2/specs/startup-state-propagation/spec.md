## MODIFIED Requirements

### Requirement: CLI writes isStarting state to cache before spawn
CLI SHALL NOT write lifecycle state directly to `last_check.json` before spawning processes. Daemon SHALL be the lifecycle state writer for service actions.

#### Scenario: Restart all uses daemon state
- **WHEN** user runs `startwatch restart failed`
- **THEN** CLI reads daemon state through `getStatus`
- **AND** sends `restartService` requests
- **AND** does not write `isStarting` directly to cache

#### Scenario: Daemon writes lifecycle state
- **WHEN** daemon accepts a background `startService` or `restartService`
- **THEN** daemon updates runtime state and later checkpoint flushes reflect that state

### Requirement: Menu bar reads isStarting from cache and reflects in icon
For PR1-6, Menu SHALL read state through timer refresh and checkpoint fallback rather than persistent event stream. Checkpoint file MAY be used for offline and timer-polled display until Stage III push is restored.

#### Scenario: Menu shows starting from refreshed state
- **WHEN** Menu refresh reads a snapshot containing a service in starting state
- **THEN** menu bar displays startup indicator

#### Scenario: Menu updates after startup transition
- **WHEN** daemon writes updated checkpoint or status becomes available through refresh
- **THEN** menu agent updates icon state on the next refresh

### Requirement: Startup state persists across daemon restarts via checkpoints
System SHALL persist daemon memory snapshots to checkpoint on schedule and shutdown. PR1-6 Menu may use checkpoint as a polling/offline display source.

#### Scenario: Startup state survives daemon restart via checkpoint
- **WHEN** daemon had persisted checkpoint and then restarts
- **THEN** restored in-memory snapshot is available for status responses before next check cycle

#### Scenario: Stale checkpoint schema is discarded
- **WHEN** daemon reads `last_check.json` and decoding fails or schemaVersion does not match
- **THEN** daemon discards the stale checkpoint state
- **AND** writes a fresh checkpoint after the next successful snapshot

#### Scenario: Timer polling reads checkpoint fallback
- **WHEN** daemon is offline and checkpoint exists
- **THEN** menu-agent may display stale checkpoint state

### Requirement: CodableCheckResult includes isStarting field
`CodableCheckResult` struct SHALL include `isStarting: Bool` field with default value `false`.

#### Scenario: Decode old cache file without isStarting field
- **WHEN** system reads `last_check.json` from before this change
- **THEN** Codable decoder defaults `isStarting` to `false`

#### Scenario: Encode new cache file with isStarting
- **WHEN** system writes new cache entries
- **THEN** JSON includes `"isStarting": true/false` field

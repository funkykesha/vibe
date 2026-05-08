## ADDED Requirements

### Requirement: Daemon state source of truth is in memory
The daemon SHALL keep runtime service state in memory as the primary source of truth. The in-memory state SHALL include `services` keyed by service name, `lastCheckTime`, and a monotonic `generation` counter incremented on each mutation.

#### Scenario: Check cycle updates memory first
- **WHEN** a daemon check cycle completes for configured services
- **THEN** service states are written to in-memory state and become immediately available for status reads and IPC publish logic without reading disk

#### Scenario: Generation changes on mutation
- **WHEN** any service status changes in memory
- **THEN** `generation` increments and can be compared against the last flushed generation to detect pending persistence work

#### Scenario: Concurrent status reads during check cycle write
- **WHEN** an IPC client requests status while check cycle updates in-memory state
- **THEN** client receives a consistent snapshot (fully before or fully after mutation), never a partial mixed-state view

### Requirement: Checkpoint persistence uses periodic flush and shutdown flush
The daemon SHALL persist in-memory state to checkpoint file at `~/.local/state/startwatch/last_check.json` using periodic flush with default interval `300` seconds and a mandatory flush on graceful shutdown. The interval SHALL be configurable in `startwatch.yml`.

#### Scenario: Periodic flush persists snapshot
- **WHEN** daemon is running and flush interval elapses
- **THEN** daemon writes checkpoint snapshot from current in-memory state to disk

#### Scenario: Periodic flush skips when state is unchanged
- **WHEN** flush timer fires and current `generation` equals `lastFlushedGeneration`
- **THEN** daemon skips checkpoint write and does not update checkpoint timestamp

#### Scenario: Graceful shutdown flushes latest state
- **WHEN** daemon receives graceful shutdown
- **THEN** daemon flushes latest in-memory snapshot before process exit

### Requirement: Checkpoint writes are crash-safe and versioned
Checkpoint writes SHALL use temp-file then atomic rename semantics. Checkpoint JSON SHALL include schema version field from initial rollout (`"version": 1`).

#### Scenario: Crash during write does not corrupt prior checkpoint
- **WHEN** daemon is interrupted during checkpoint write
- **THEN** previous valid checkpoint remains readable on next startup

#### Scenario: Checkpoint contains schema version
- **WHEN** daemon writes checkpoint
- **THEN** JSON includes `version`, `timestamp`, and `services` fields

### Requirement: Daemon restores startup state from latest valid checkpoint
On daemon startup, system SHALL load the latest valid checkpoint into in-memory state before first check cycle. If checkpoint decode fails, system SHALL fall back to empty/default state and continue startup.

#### Scenario: Valid checkpoint restore
- **WHEN** daemon starts with valid checkpoint present
- **THEN** in-memory state is initialized from checkpoint and available to status/IPC immediately

#### Scenario: Corrupted checkpoint fallback
- **WHEN** daemon starts and checkpoint file is malformed
- **THEN** daemon logs restore warning, initializes empty/default state, and remains operational

#### Scenario: First-ever daemon start without checkpoint
- **WHEN** daemon starts and checkpoint file does not exist
- **THEN** daemon initializes empty/default state, logs informational restore message, and proceeds to first check cycle normally

### Requirement: State size remains bounded by configured services
In-memory state SHALL be keyed only by services present in current configuration. Services removed from config SHALL be pruned from in-memory state on subsequent check cycles.

#### Scenario: Removed service is pruned
- **WHEN** a service is deleted from configuration and next check cycle runs
- **THEN** service entry is removed from in-memory state and no historical entry is retained

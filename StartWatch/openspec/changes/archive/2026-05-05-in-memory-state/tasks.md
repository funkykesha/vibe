## 1. State Manager In-Memory Source of Truth

- [x] 1.1 Define `StateManager` in-memory model (`services` map, `lastCheckTime`, `generation`, `lastFlushedGeneration`) and expose consistent snapshot read API
- [x] 1.2 Implement concurrency model with concurrent reads and barrier writes to guarantee no partial snapshot visibility
- [x] 1.3 Update check-cycle write path to mutate only in-memory state and increment `generation` on each mutation
- [x] 1.4 Add service-pruning logic so entries removed from config are dropped from in-memory state on next check cycle

## 2. Checkpoint Persistence and Restore

- [x] 2.1 Implement checkpoint writer for `~/.local/state/startwatch/last_check.json` using temp-file + atomic rename
- [x] 2.2 Add checkpoint schema version field (`version: 1`) and stable snapshot payload (`version`, `timestamp`, `services`)
- [x] 2.3 Implement periodic flush scheduler with default `300s` interval and `startwatch.yml` override
- [x] 2.4 Implement flush skip optimization (`generation == lastFlushedGeneration` => no disk write, no timestamp update)
- [x] 2.5 Implement mandatory graceful-shutdown flush and critical-transition-triggered flush hooks per design policy
- [x] 2.6 Implement startup restore flow: load valid checkpoint into memory, handle missing file as normal empty-state path, and handle malformed checkpoint with warning + fallback

## 3. Runtime Integration and Offline Fallback

- [x] 3.1 Wire daemon status/checker integration to consume and publish only in-memory snapshots during normal runtime
- [x] 3.2 Implement start-command transition behavior: set service to `starting` in memory, increment generation, emit state-change event before process launch
- [x] 3.3 Implement CLI daemon-offline fallback for `status`: read checkpoint file directly and show `⚠️ Daemon offline. Last state from <relative_time>:` header
- [x] 3.4 Ensure runtime live paths do not read checkpoint file while daemon socket is available

## 4. Stage III Dependency Gate (bidirectional-unix-socket)

- [x] 4.1 Integrate in-memory state as source for IPC `getStatus` responses once Stage III socket request/response path is present
- [x] 4.2 Integrate in-memory state with IPC subscriber broadcast path (`statusSnapshot`/`serviceChanged`) once Stage III subscribe/push flow is merged
- [x] 4.3 Remove/disable remaining live polling/file-read transport paths only after Stage III integration passes regression checks

## 5. Validation and Regression Coverage

- [x] 5.1 Add/adjust unit tests for in-memory state model: generation increments, consistent concurrent snapshot reads, and service-pruning behavior
- [x] 5.2 Add persistence tests: periodic flush, flush-skip-on-unchanged-state, shutdown flush, atomic-write recovery, and schema version encoding
- [x] 5.3 Add restore tests: valid checkpoint restore, first-start-without-file path, and malformed-checkpoint fallback
- [x] 5.4 Add integration tests for CLI offline fallback staleness output and no live disk-read behavior when daemon is available
- [x] 5.5 Run `swift test` and confirm all tests pass before marking change ready for apply/archive

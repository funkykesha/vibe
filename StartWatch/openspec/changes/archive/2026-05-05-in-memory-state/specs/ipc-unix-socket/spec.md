## MODIFIED Requirements

> Extends requirements from `openspec/changes/bidirectional-unix-socket/specs/ipc-unix-socket/spec.md`.
> Adds in-memory source-of-truth constraints to existing bidirectional IPC behavior.

### Requirement: Daemon exposes Unix domain socket
The daemon SHALL serve IPC status responses from in-memory state as source of truth. Checkpoint file SHALL NOT be used as a live read source while daemon is running.

#### Scenario: Status served from memory
- **WHEN** connected client requests status while daemon is running
- **THEN** daemon replies using current in-memory snapshot without reading checkpoint from disk

#### Scenario: Startup restored state available immediately
- **WHEN** daemon starts and loads valid checkpoint into memory
- **THEN** first IPC status response can return restored state before first check cycle completes

### Requirement: CLI and menu-agent send commands via socket
CLI and menu-agent SHALL use socket IPC for live runtime state access when daemon is available. If socket is unavailable, CLI `status` SHALL fall back to reading `last_check.json` directly and report staleness.

#### Scenario: Live runtime path uses socket
- **WHEN** daemon socket is available and `startwatch status` is invoked
- **THEN** CLI fetches state through socket path and does not read checkpoint file

#### Scenario: Offline fallback path reads checkpoint
- **WHEN** daemon socket is unavailable and `startwatch status` is invoked
- **THEN** CLI reads `last_check.json` and prints daemon-offline stale-state indicator

#### Scenario: Staleness display format
- **WHEN** CLI reads checkpoint in offline fallback mode
- **THEN** output includes header `⚠️ Daemon offline. Last state from <relative_time>:` where `<relative_time>` is human-readable duration since checkpoint timestamp

## MODIFIED Requirements

### Requirement: Menu uses event-driven updates from daemon
Menu-agent SHALL use event-driven state updates from daemon subscription as the primary live update mechanism. It SHALL not run periodic cache polling for live state transitions. If daemon is disconnected, menu-agent SHALL show offline state and attempt reconnect; after reconnect it SHALL refresh from `statusSnapshot`.

#### Scenario: Live update without polling
- **WHEN** daemon emits `serviceChanged` for a subscribed menu-agent
- **THEN** menu-agent updates affected menu item immediately without reading cache file on a timer

#### Scenario: Offline state during daemon outage
- **WHEN** menu-agent subscription connection drops
- **THEN** menu-agent displays daemon offline indicator and schedules reconnect attempts

#### Scenario: State recovery after reconnect
- **WHEN** reconnect succeeds and menu-agent sends `subscribe`
- **THEN** daemon returns `statusSnapshot` and menu-agent rebuilds menu state from that snapshot

#### Scenario: Stale state display during extended outage
- **WHEN** daemon is unavailable for more than 30 seconds
- **THEN** menu-agent shows last known state with a visual staleness indicator

#### Scenario: Reconnect backoff
- **WHEN** reconnect attempt fails
- **THEN** menu-agent retries with exponential backoff starting at 2 seconds and capped at 60 seconds

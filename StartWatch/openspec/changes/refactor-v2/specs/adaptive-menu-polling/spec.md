## MODIFIED Requirements

### Requirement: Menu uses event-driven updates from daemon
For PR1-6, menu-agent SHALL use timer-based polling instead of event-driven daemon subscription. It SHALL poll while online, poll less frequently while offline, refresh after actions, and show stale checkpoint state when daemon is unavailable. Persistent subscription becomes a later-stage behavior.

#### Scenario: Online polling interval
- **WHEN** daemon is reachable
- **THEN** menu-agent refreshes status every 3 seconds

#### Scenario: Offline polling interval
- **WHEN** daemon is unavailable
- **THEN** menu-agent refreshes offline state every 5 seconds

#### Scenario: Refresh after action
- **WHEN** menu-agent sends a service action or triggerCheck
- **THEN** menu-agent performs an immediate refresh attempt
- **AND** refresh is coalesced if another refresh is already in flight

#### Scenario: Stale state display during outage
- **WHEN** daemon is unavailable and `last_check.json` exists
- **THEN** menu-agent shows last known state with staleness derived from snapshot timestamp when present, falling back to file mtime

#### Scenario: Subscribe deferred
- **WHEN** PR1-6 menu-agent starts
- **THEN** it does not require persistent `subscribe` to render state

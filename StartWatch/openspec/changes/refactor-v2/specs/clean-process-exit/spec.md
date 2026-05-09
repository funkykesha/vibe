## MODIFIED Requirements

### Requirement: Daemon exits cleanly on shutdown signal
The daemon SHALL terminate completely with exit code 0 when daemon shutdown is initiated, with all daemon-owned resources released and no daemon-owned timers left running. Menu Agent shutdown is a separate UI action and SHALL NOT be required for daemon clean exit.

#### Scenario: User requests daemon quit from menu
- **WHEN** user clicks Stop Daemon in Menu
- **THEN** menu-agent sends quit command to daemon
- **THEN** IPC server receives quit command and calls shutdown
- **THEN** daemon-owned timers and scheduled checks are cancelled
- **THEN** daemon flushes state and closes IPC socket
- **THEN** daemon calls exit(0) and terminates
- **THEN** menu-agent remains running and shows offline state

#### Scenario: User runs CLI quit
- **WHEN** user runs `startwatch quit`
- **THEN** CLI sends quit command to daemon
- **THEN** daemon performs clean shutdown and exits 0

#### Scenario: No orphan timers after shutdown
- **WHEN** shutdown is called with active repeating timers
- **THEN** daemon timers are invalidated immediately
- **THEN** no daemon timer fires after shutdown completes

#### Scenario: No launchd respawn on clean shutdown
- **WHEN** daemon exits with code 0 after shutdown
- **THEN** launchd interprets exit as successful
- **THEN** daemon does not respawn automatically under `KeepAlive={SuccessfulExit=false}`

### Requirement: Shutdown handles edge cases without hanging
The shutdown process SHALL complete within reasonable time (< 5s) even if components are slow to respond.

#### Scenario: IPC server stops without deadlock
- **WHEN** ipcServer.stop() is called during shutdown
- **THEN** method returns without blocking
- **THEN** no threads or queues are deadlocked

#### Scenario: Scheduler cleanup is immediate
- **WHEN** scheduler is stopped
- **THEN** scheduler instance deinitializes without blocking
- **THEN** pending check operations are discarded

### Requirement: CLI stop terminates daemon and menu-agent
The `startwatch stop` command SHALL no longer stop StartWatch runtime processes. `startwatch stop <name>` stops a service, and `startwatch quit` requests daemon shutdown. Menu Agent remains a separate process controlled by Quit Menu.

#### Scenario: User runs CLI stop with service name
- **WHEN** user runs `startwatch stop redis`
- **THEN** CLI sends `stopService(name: "redis")`
- **AND** does not terminate menu-agent

#### Scenario: User runs CLI stop without service name
- **WHEN** user runs `startwatch stop`
- **THEN** CLI exits with an error and hint `Did you mean 'startwatch quit'?`

#### Scenario: User runs CLI quit
- **WHEN** user runs `startwatch quit`
- **THEN** CLI requests daemon shutdown
- **AND** does not terminate menu-agent

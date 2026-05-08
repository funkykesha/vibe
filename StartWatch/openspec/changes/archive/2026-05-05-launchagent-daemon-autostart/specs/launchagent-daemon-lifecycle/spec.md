## ADDED Requirements

### Requirement: Daemon lifecycle SHALL be managed by LaunchAgent
The system SHALL provide a LaunchAgent definition for label `com.startwatch.daemon` that runs `startwatch daemon`, starts at login, and restarts after abnormal termination.

#### Scenario: LaunchAgent starts daemon at login
- **WHEN** user session loads LaunchAgent `com.startwatch.daemon`
- **THEN** launchd starts `startwatch daemon` without requiring menu-agent or CLI bootstrap

#### Scenario: Daemon restarts after crash
- **WHEN** daemon process exits abnormally (for example after `kill -9`)
- **THEN** launchd restarts daemon according to LaunchAgent keepalive policy

### Requirement: CLI SHALL manage LaunchAgent installation lifecycle
The CLI SHALL provide `startwatch install` and `startwatch uninstall` commands to install, load, unload, and remove LaunchAgent `com.startwatch.daemon`.

#### Scenario: Install command configures autostart
- **WHEN** user runs `startwatch install`
- **THEN** CLI writes `~/Library/LaunchAgents/com.startwatch.daemon.plist`, bootstraps it into launchd, and reports success or actionable failure

#### Scenario: Uninstall command removes autostart
- **WHEN** user runs `startwatch uninstall`
- **THEN** CLI boots out launchd job `com.startwatch.daemon`, removes its plist, and reports completion

### Requirement: Clients SHALL not bootstrap daemon via app launch hacks
CLI and menu-agent clients SHALL not launch `StartWatchMenu.app` (or any app bundle) to recover missing daemon IPC socket.

#### Scenario: CLI command when daemon is offline
- **WHEN** a CLI command requiring daemon IPC executes while daemon socket is unavailable
- **THEN** CLI returns daemon-not-running guidance with install/manual-start hint and does not call `open -na`

### Requirement: Menu-agent SHALL expose daemon offline state
Menu-agent SHALL operate as a UI client and expose explicit offline state with an action to start daemon through launchctl.

#### Scenario: Offline daemon in menu
- **WHEN** menu-agent detects daemon is unavailable
- **THEN** menu shows `Daemon not running` state and provides a start action that calls `launchctl kickstart -k gui/<uid>/com.startwatch.daemon`

### Requirement: Daemon SHALL gracefully handle SIGTERM
Daemon SHALL intercept SIGTERM and perform graceful shutdown with cleanup and persistence before exit.

#### Scenario: SIGTERM shutdown path
- **WHEN** daemon receives SIGTERM from launchd or user tooling
- **THEN** daemon executes shutdown routine, flushes state, closes IPC server/socket, and exits cleanly

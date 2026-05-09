## MODIFIED Requirements

### Requirement: Daemon lifecycle SHALL be managed by LaunchAgent
The system SHALL provide a LaunchAgent definition for label `com.user.startwatch` that runs `/usr/local/bin/startwatch daemon`, starts at login, does not restart after clean `exit(0)`, and restarts after abnormal termination.

#### Scenario: LaunchAgent starts daemon at login
- **WHEN** user session loads LaunchAgent `com.user.startwatch`
- **THEN** launchd starts `/usr/local/bin/startwatch daemon` without requiring menu-agent or CLI bootstrap

#### Scenario: Daemon restarts after crash
- **WHEN** daemon process exits abnormally
- **THEN** launchd restarts daemon subject to `ThrottleInterval`

#### Scenario: Clean quit stays down
- **WHEN** daemon exits with code 0 after IPC `quit`
- **THEN** launchd does not restart daemon automatically

### Requirement: CLI SHALL manage LaunchAgent installation lifecycle
The CLI SHALL provide `startwatch install` and `startwatch uninstall` commands to install, load, unload, and remove LaunchAgent `com.user.startwatch`. `startwatch install` SHALL repair LaunchAgent only and SHALL NOT build, copy, or codesign installed binaries.

#### Scenario: Install command configures autostart
- **WHEN** user runs `startwatch install`
- **THEN** CLI writes `~/Library/LaunchAgents/com.user.startwatch.plist`, bootstraps it into launchd, and reports success or actionable failure

#### Scenario: Uninstall command removes autostart
- **WHEN** user runs `startwatch uninstall`
- **THEN** CLI boots out launchd job `com.user.startwatch`, removes its plist, and reports completion

### Requirement: Clients SHALL not bootstrap daemon via app launch hacks
CLI and menu-agent clients SHALL not launch `StartWatchMenu.app` to recover missing daemon IPC socket.

#### Scenario: CLI command when daemon is offline
- **WHEN** a CLI command requiring daemon IPC executes while daemon socket is unavailable
- **THEN** CLI returns daemon-not-running guidance with install/manual-start hint
- **AND** it does not call `open -na`

### Requirement: Menu-agent SHALL expose daemon offline state
Menu-agent SHALL operate as a UI client and expose explicit offline state with an action to start daemon through launchctl.

#### Scenario: Offline daemon in menu
- **WHEN** menu-agent detects daemon is unavailable
- **THEN** menu shows `Daemon offline` state
- **AND** provides a start action that calls `launchctl kickstart gui/<uid>/com.user.startwatch`

### Requirement: Daemon SHALL gracefully handle SIGTERM
Daemon SHALL intercept SIGTERM and perform graceful shutdown with cleanup and persistence before exit.

#### Scenario: SIGTERM shutdown path
- **WHEN** daemon receives SIGTERM from launchd or user tooling
- **THEN** daemon executes shutdown routine, flushes state, closes IPC server/socket, and exits cleanly

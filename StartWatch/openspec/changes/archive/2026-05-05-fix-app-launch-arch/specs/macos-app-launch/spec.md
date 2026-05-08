## ADDED Requirements

### Requirement: App bundle launch ensures visible UI and daemon readiness
The system SHALL treat a no-argument launch of `/Applications/StartWatchMenu.app` as the primary macOS app launch path, starting the menu-agent and ensuring the LaunchAgent-backed daemon is running.

#### Scenario: User double-clicks installed app
- **WHEN** the user launches `/Applications/StartWatchMenu.app` without command-line arguments
- **THEN** the system starts the menu-agent UI from the app bundle process
- **THEN** the system ensures the daemon LaunchAgent is bootstrapped or kickstarted

#### Scenario: Daemon is already running
- **WHEN** the user launches `/Applications/StartWatchMenu.app` and the daemon is already running
- **THEN** the system does not start a duplicate daemon
- **THEN** the menu-agent connects to existing daemon state

#### Scenario: Daemon cannot be started
- **WHEN** the user launches `/Applications/StartWatchMenu.app` and LaunchAgent daemon startup fails
- **THEN** the menu-agent remains running
- **THEN** the UI exposes daemon-not-running state instead of silently exiting

### Requirement: App launch is idempotent for menu-agent
The system SHALL avoid creating duplicate persistent menu-agent instances when the app is opened repeatedly.

#### Scenario: User opens app repeatedly
- **WHEN** the user launches `/Applications/StartWatchMenu.app` multiple times
- **THEN** at most one persistent menu-agent owns the status item
- **THEN** repeated launches focus or reuse the existing app lifecycle without duplicate menu bar icons

### Requirement: CLI commands remain command-routed inside app bundle
The system SHALL continue routing explicit CLI commands through `CLIRouter` even when the executable path is inside the app bundle.

#### Scenario: User runs bundled binary status command
- **WHEN** `/Applications/StartWatchMenu.app/Contents/MacOS/startwatch status` is executed
- **THEN** the system routes the command through CLI status behavior
- **THEN** the system does not enter `NSApplication.run()`

#### Scenario: User runs bundled binary check command
- **WHEN** `/Applications/StartWatchMenu.app/Contents/MacOS/startwatch check` is executed
- **THEN** the system routes the command through CLI check behavior
- **THEN** the process exits after command completion

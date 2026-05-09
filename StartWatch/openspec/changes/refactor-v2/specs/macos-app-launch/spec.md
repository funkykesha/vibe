## MODIFIED Requirements

### Requirement: App bundle launch ensures visible UI and daemon readiness
The system SHALL treat every launch of `/Applications/StartWatchMenu.app` as the Menu Agent app launch path. It SHALL create menu UI even when daemon is unavailable, and SHALL NOT start daemon runtime in the app-bundle process.

#### Scenario: User double-clicks installed app
- **WHEN** the user launches `/Applications/StartWatchMenu.app`
- **THEN** the system starts the menu-agent UI from the app bundle process
- **THEN** it creates `NSStatusItem` immediately

#### Scenario: Daemon is already running
- **WHEN** the user launches `/Applications/StartWatchMenu.app` and the daemon is already running
- **THEN** menu-agent connects as an IPC client
- **THEN** no duplicate daemon is started in the app-bundle process

#### Scenario: Daemon cannot be started
- **WHEN** the user launches `/Applications/StartWatchMenu.app` and daemon is unavailable
- **THEN** the menu-agent remains running
- **THEN** the UI exposes daemon-offline state instead of silently exiting

### Requirement: App launch is idempotent for menu-agent
The system SHALL avoid creating duplicate persistent menu-agent instances when the app is opened repeatedly.

#### Scenario: User opens app repeatedly
- **WHEN** the user launches `/Applications/StartWatchMenu.app` multiple times
- **THEN** at most one persistent menu-agent owns the status item
- **THEN** repeated launches do not create duplicate menu bar icons

### Requirement: CLI commands remain command-routed inside app bundle
The app-bundle binary SHALL NOT be used as a CLI routing path in the installed runtime. Any app-bundle process SHALL run Menu Agent behavior, while CLI commands SHALL run from `/usr/local/bin/startwatch`.

#### Scenario: User runs CLI status
- **WHEN** user runs `/usr/local/bin/startwatch status`
- **THEN** the system routes through CLI status behavior
- **AND** the process is not running from the app bundle

#### Scenario: App bundle receives explicit arguments
- **WHEN** `/Applications/StartWatchMenu.app/Contents/MacOS/startwatch status` is executed
- **THEN** the process still runs Menu Agent behavior
- **AND** it does not enter CLI status behavior

#### Scenario: App bundle receives daemon argument
- **WHEN** `/Applications/StartWatchMenu.app/Contents/MacOS/startwatch daemon` is executed
- **THEN** the process still runs Menu Agent behavior
- **AND** it does not enter daemon runtime behavior

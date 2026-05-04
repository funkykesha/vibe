## MODIFIED Requirements

### Requirement: Daemon checks for .app existence before spawn
System SHALL NOT use the daemon as the persistent owner of menu-agent lifecycle. Daemon-started menu-agent spawning is removed from normal LaunchAgent operation; menu-agent startup belongs to the app launch path.

#### Scenario: LaunchAgent starts headless daemon
- **WHEN** LaunchAgent starts `/Applications/StartWatchMenu.app/Contents/MacOS/startwatch daemon --no-menu`
- **THEN** daemon starts monitoring without attempting to spawn menu-agent

#### Scenario: App bundle is missing
- **WHEN** daemon starts in an environment without `/Applications/StartWatchMenu.app`
- **THEN** daemon continues headless monitoring without attempting app-bundle UI spawn

#### Scenario: User starts daemon without no-menu flag
- **WHEN** user runs `startwatch daemon` manually
- **THEN** daemon may start monitoring
- **THEN** daemon does not periodically respawn persistent menu-agent ownership by default

### Requirement: --no-menu flag enables headless daemon mode
Daemon SHALL accept `--no-menu` flag and not attempt to spawn menu agent when present.

#### Scenario: Daemon with --no-menu flag
- **WHEN** user runs `./startwatch daemon --no-menu`
- **THEN** daemon starts but never attempts menu agent spawn

#### Scenario: Daemon without --no-menu flag
- **WHEN** user runs `./startwatch daemon`
- **THEN** daemon starts monitoring without LaunchAgent-specific UI respawn behavior

## ADDED Requirements

### Requirement: LaunchAgent starts bundle binary in headless mode
LaunchAgent SHALL start the daemon directly from `/Applications/StartWatchMenu.app/Contents/MacOS/startwatch` with `daemon --no-menu`.

#### Scenario: LaunchAgent plist is installed
- **WHEN** installation writes `~/Library/LaunchAgents/com.user.startwatch.plist`
- **THEN** `ProgramArguments` contains `/Applications/StartWatchMenu.app/Contents/MacOS/startwatch`
- **THEN** `ProgramArguments` contains `daemon`
- **THEN** `ProgramArguments` contains `--no-menu`

### Requirement: LaunchAgent template uses final runtime path
The checked-in LaunchAgent template SHALL represent the final runtime model and not require sed replacement from `/usr/local/bin/startwatch` to the bundle binary.

#### Scenario: Installer copies LaunchAgent
- **WHEN** installer creates the user LaunchAgent plist
- **THEN** the daemon executable path comes from the app bundle binary source of truth
- **THEN** installer does not depend on rewriting a CLI-wrapper path into a daemon path

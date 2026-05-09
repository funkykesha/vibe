## MODIFIED Requirements

### Requirement: Daemon checks for .app existence before spawn
System SHALL NOT use the daemon as the persistent owner of menu-agent lifecycle. Daemon-started menu-agent spawning is removed from normal operation; menu-agent startup belongs only to the app bundle launch path.

#### Scenario: LaunchAgent starts headless daemon
- **WHEN** LaunchAgent starts `/usr/local/bin/startwatch daemon`
- **THEN** daemon starts monitoring without attempting to spawn menu-agent

#### Scenario: App bundle is missing
- **WHEN** daemon starts in an environment without `/Applications/StartWatchMenu.app`
- **THEN** daemon continues headless monitoring without attempting app-bundle UI spawn

#### Scenario: User starts daemon manually
- **WHEN** user runs `startwatch daemon` manually
- **THEN** daemon starts monitoring headlessly
- **AND** daemon does not start or manage menu-agent

### Requirement: --no-menu flag enables headless daemon mode
Daemon SHALL be headless by role. The `--no-menu` flag SHALL be removed and SHALL NOT be required to prevent UI startup.

#### Scenario: Daemon command has no menu mode
- **WHEN** user runs `startwatch daemon`
- **THEN** daemon starts headless runtime
- **AND** no `showMenu` branch exists

#### Scenario: Legacy no-menu flag is rejected
- **WHEN** user passes `--no-menu`
- **THEN** CLI exits non-zero with `unknown flag: --no-menu`

### Requirement: LaunchAgent starts bundle binary in headless mode
LaunchAgent SHALL start the daemon from `/usr/local/bin/startwatch` with argument `daemon`. It SHALL NOT start the app bundle binary and SHALL NOT pass `--no-menu`.

#### Scenario: LaunchAgent plist is installed
- **WHEN** installation writes `~/Library/LaunchAgents/com.user.startwatch.plist`
- **THEN** `ProgramArguments` contains `/usr/local/bin/startwatch`
- **THEN** `ProgramArguments` contains `daemon`
- **THEN** `ProgramArguments` does not contain `--no-menu`

### Requirement: LaunchAgent template uses final runtime path
The checked-in LaunchAgent template SHALL represent the final runtime model and not require sed replacement from `/usr/local/bin/startwatch` to the bundle binary.

#### Scenario: Installer copies LaunchAgent
- **WHEN** installer creates the user LaunchAgent plist
- **THEN** the daemon executable path is `/usr/local/bin/startwatch`
- **THEN** installer does not depend on rewriting a CLI-wrapper path into a daemon path

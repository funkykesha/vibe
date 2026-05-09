## ADDED Requirements

### Requirement: Installer SHALL deploy one build artifact as two physical copies
The installer SHALL copy the same release Mach-O to `/usr/local/bin/startwatch` and `/Applications/StartWatchMenu.app/Contents/MacOS/startwatch`.

#### Scenario: CLI binary installed
- **WHEN** `install.sh` completes
- **THEN** `/usr/local/bin/startwatch` is an executable Mach-O binary
- **AND** it is not a shell wrapper

#### Scenario: Menu bundle binary installed
- **WHEN** `install.sh` completes
- **THEN** `/Applications/StartWatchMenu.app/Contents/MacOS/startwatch` exists
- **AND** the app bundle identifier is `com.user.startwatch.menu`

### Requirement: LaunchAgent SHALL run CLI binary daemon role
LaunchAgent `com.user.startwatch` SHALL run `/usr/local/bin/startwatch daemon`.

#### Scenario: LaunchAgent program arguments
- **WHEN** installer writes `~/Library/LaunchAgents/com.user.startwatch.plist`
- **THEN** `ProgramArguments` equals `/usr/local/bin/startwatch`, `daemon`
- **AND** it does not include `--no-menu`

### Requirement: LaunchAgent SHALL distinguish clean quit from failure
LaunchAgent SHALL include `RunAtLoad=true`, `KeepAlive={SuccessfulExit=false}`, and `ThrottleInterval=10`.

#### Scenario: Clean quit stays stopped
- **WHEN** daemon exits with code 0 after IPC `quit`
- **THEN** launchd does not relaunch daemon automatically

#### Scenario: Crash restarts
- **WHEN** daemon exits with non-zero status
- **THEN** launchd may relaunch daemon subject to `ThrottleInterval`

### Requirement: Runtime socket path SHALL be user-private
State directory and socket file permissions SHALL prevent other users from controlling the daemon.

#### Scenario: State directory mode
- **WHEN** daemon or installer creates `~/.local/state/startwatch`
- **THEN** directory mode is `0700`

#### Scenario: Socket file mode
- **WHEN** daemon binds `~/.local/state/startwatch/sock`
- **THEN** socket file mode is `0600`

### Requirement: startwatch install SHALL repair LaunchAgent only
The installed CLI `startwatch install` SHALL repair/bootstrap the LaunchAgent for an already installed binary and app bundle. It SHALL not perform full build, binary copy, or codesign steps.

#### Scenario: Repair install
- **WHEN** user runs `startwatch install`
- **THEN** CLI writes or repairs LaunchAgent plist
- **AND** bootstraps or kickstarts `com.user.startwatch`

### Requirement: Installer SHALL refresh LaunchServices for menu bundle
After copying `/Applications/StartWatchMenu.app`, installer SHALL run `lsregister -f` on the bundle path before opening it. Failure of `lsregister` SHALL be logged but SHALL NOT abort install.

#### Scenario: lsregister runs after bundle copy
- **WHEN** `install.sh` copies the app bundle
- **THEN** `install.sh` runs `lsregister -f /Applications/StartWatchMenu.app`
- **AND** runs it before `open -na`

#### Scenario: lsregister failure is non-fatal
- **WHEN** `lsregister` exits non-zero
- **THEN** `install.sh` logs the failure
- **AND** continues to launch the app

#### Scenario: doctor verifies LaunchServices resolution
- **WHEN** `startwatch doctor` runs
- **THEN** it queries LaunchServices for `com.user.startwatch.menu`
- **AND** verifies the resolved path is `/Applications/StartWatchMenu.app`

# workguard-login-autostart Specification

## Purpose
TBD - created by archiving change install-workguard-applications-launchagent. Update Purpose after archive.
## Requirements
### Requirement: LaunchAgent location and label
The system SHALL configure WorkGuard login startup using `~/Library/LaunchAgents/com.agaibadulin.workguard.plist` with label `com.agaibadulin.workguard`.

#### Scenario: Rebuild writes LaunchAgent plist
- **WHEN** `bash rebuild.sh` completes successfully
- **THEN** `~/Library/LaunchAgents/com.agaibadulin.workguard.plist` exists
- **THEN** the plist `Label` is `com.agaibadulin.workguard`

### Requirement: LaunchAgent opens installed app
The WorkGuard LaunchAgent SHALL use `/usr/bin/open` to open `/Applications/WorkGuard.app` rather than executing Python or a project-local app directly.

#### Scenario: LaunchAgent ProgramArguments are fixed
- **WHEN** the WorkGuard LaunchAgent plist is generated
- **THEN** `ProgramArguments` contains exactly `/usr/bin/open` followed by `/Applications/WorkGuard.app`

### Requirement: LaunchAgent startup flags
The WorkGuard LaunchAgent SHALL use `RunAtLoad=true` and `KeepAlive=false`.

#### Scenario: LaunchAgent flags are fixed
- **WHEN** the WorkGuard LaunchAgent plist is generated
- **THEN** `RunAtLoad` is `true`
- **THEN** `KeepAlive` is `false`

### Requirement: LaunchAgent reload during rebuild
The system SHALL reload the WorkGuard LaunchAgent in the current user's launchd domain during rebuild.

#### Scenario: Rebuild reloads LaunchAgent
- **WHEN** `bash rebuild.sh` writes the WorkGuard LaunchAgent plist
- **THEN** it runs `launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.agaibadulin.workguard.plist` tolerating an already-unloaded agent
- **THEN** it runs `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.agaibadulin.workguard.plist`

### Requirement: LaunchAgent verification
The system SHALL support verification that the WorkGuard LaunchAgent is loaded after rebuild.

#### Scenario: LaunchAgent is visible to launchctl
- **WHEN** `bash rebuild.sh` completes successfully
- **THEN** `launchctl print gui/$(id -u)/com.agaibadulin.workguard` succeeds

### Requirement: Stop failure aborts reinstall
The rebuild flow MUST abort when `scripts/stop_workguard.sh` exits non-zero.

#### Scenario: Stop script fails
- **WHEN** `scripts/stop_workguard.sh` returns a non-zero exit during rebuild
- **THEN** `bash rebuild.sh` exits non-zero
- **THEN** it does not replace `/Applications/WorkGuard.app`
- **THEN** it does not rewrite or reload the WorkGuard LaunchAgent
- **THEN** it does not relaunch WorkGuard


## ADDED Requirements

### Requirement: Daemon monitors config file for changes

The system SHALL monitor the config file at `~/.config/startwatch/config.json` for modifications and reload it automatically without requiring daemon restart.

#### Scenario: Config file is edited
- **WHEN** user modifies the config file and saves it
- **THEN** daemon detects the change within 1 second
- **THEN** daemon reloads the config without restarting

#### Scenario: Config reload during active checks
- **WHEN** config is reloaded while a service check is running
- **THEN** the in-flight check completes with the previous config snapshot
- **THEN** the next check uses the new config

#### Scenario: User removes config file
- **WHEN** config file is deleted
- **THEN** daemon logs a warning
- **THEN** daemon continues using the last valid config

### Requirement: Config reload is logged

The system SHALL log all config reload events with details about what changed.

#### Scenario: Successful reload
- **WHEN** config file is reloaded
- **THEN** daemon logs: "Config reloaded from ~/.config/startwatch/config.json"
- **THEN** log includes number of services before and after

#### Scenario: No changes detected
- **WHEN** config file is saved but content is unchanged
- **THEN** daemon detects the file change but skips reload
- **THEN** no unnecessary log entry is created

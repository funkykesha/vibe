## ADDED Requirements

### Requirement: Log config file access
System SHALL log when config file is accessed (opened for reading) including success or error.

#### Scenario: Config file found and readable
- **WHEN** application attempts to load config from ~/.config/startwatch/config.json
- **THEN** system logs: timestamp, "CONFIG_LOAD_START", file path, success indicator

#### Scenario: Config file not found
- **WHEN** application attempts to load config and file does not exist
- **THEN** system logs: timestamp, "CONFIG_LOAD_ERROR", file path, error reason

### Requirement: Log config parsing
System SHALL log when config JSON is parsed, including whether parsing succeeds or fails.

#### Scenario: Config parses successfully
- **WHEN** ConfigManager.load() parses AppConfig from JSON
- **THEN** system logs: timestamp, "CONFIG_PARSE_SUCCESS", count of services

#### Scenario: Config parsing fails (invalid JSON)
- **WHEN** JSON in config.json is malformed
- **THEN** system logs: timestamp, "CONFIG_PARSE_ERROR", error message from decoder

### Requirement: Log config validation
System SHALL log when loaded config is validated against schema constraints.

#### Scenario: Config passes validation
- **WHEN** AppConfig structure is valid (all required fields present, types correct)
- **THEN** system logs: timestamp, "CONFIG_VALIDATE_SUCCESS", validation details

#### Scenario: Config fails validation
- **WHEN** AppConfig is missing required fields or has type mismatches
- **THEN** system logs: timestamp, "CONFIG_VALIDATE_ERROR", which field failed and why

### Requirement: Log config application
System SHALL log when parsed config is applied to runtime state.

#### Scenario: Config applied to services
- **WHEN** ConfigManager applies loaded AppConfig to service registry (check intervals, service list, etc.)
- **THEN** system logs: timestamp, "CONFIG_APPLY_SUCCESS", services count, relevant config changes

#### Scenario: Service configuration change detected
- **WHEN** reloaded config differs from previously loaded config (e.g., service added, interval changed)
- **THEN** system logs: timestamp, "CONFIG_CHANGE_DETECTED", delta summary (added/removed/modified services)

### Requirement: Structured log format for config logs
All config logs SHALL follow format: `{timestamp, level, component, event, details}` as JSON line.

#### Scenario: Example log entry
- **WHEN** config logging occurs
- **THEN** log entry format: `{"timestamp":"2026-04-30T10:15:23Z","level":"INFO","component":"ConfigManager","event":"CONFIG_PARSE_SUCCESS","details":{"serviceCount":5}}`

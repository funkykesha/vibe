## ADDED Requirements

### Requirement: Config is validated on load with error logging

The system SHALL validate the config file when loaded, log any errors, and reject invalid configs while keeping the previous valid config in effect.

#### Scenario: Valid config
- **WHEN** config is loaded and passes validation
- **THEN** the new config is applied
- **THEN** no error messages are logged

#### Scenario: Invalid config (missing required field)
- **WHEN** config is loaded with missing service name or check value
- **THEN** validation fails
- **THEN** daemon logs error: "Config validation failed: Service has empty name"
- **THEN** the new config is rejected
- **THEN** the previous valid config remains in effect
- **THEN** services continue checking with old config

#### Scenario: Config file is not valid JSON
- **WHEN** config file contains invalid JSON syntax
- **THEN** daemon logs error: "Failed to parse config.json: [JSON error details]"
- **THEN** the previous valid config remains in effect

#### Scenario: Config with unknown fields
- **WHEN** config contains extra unknown fields (forward compatibility)
- **THEN** unknown fields are ignored
- **THEN** config is accepted if all required fields are present
- **THEN** no warning is logged

### Requirement: Validation logs are actionable

The system SHALL provide clear error messages that guide the user to fix config issues.

#### Scenario: Service validation error
- **WHEN** validation detects an empty check value
- **THEN** log includes: service name, field name, and example of valid value
- **THEN** example shows: "Service 'Eliza Proxy' has empty check value. Example: {\"type\": \"http\", \"value\": \"http://localhost:3100\"}"

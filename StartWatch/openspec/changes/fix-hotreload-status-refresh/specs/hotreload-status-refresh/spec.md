## ADDED Requirements

### Requirement: Status cache updates after config reload
When the daemon detects a config file change and successfully reloads it, the system SHALL immediately run a service check and update the status cache — without waiting for the next scheduled check.

#### Scenario: New service added to config
- **WHEN** user adds a new service to `~/.config/startwatch/config.json`
- **THEN** within 2 seconds `startwatch status` shows the new service

#### Scenario: Service removed from config
- **WHEN** user removes a service from `~/.config/startwatch/config.json`
- **THEN** within 2 seconds `startwatch status` no longer shows the removed service

#### Scenario: Invalid config does not trigger check
- **WHEN** user saves an invalid config (e.g., missing required `check.value`)
- **THEN** the daemon keeps the previous config and does NOT trigger a new check
- **THEN** `startwatch status` still shows the previous valid service list

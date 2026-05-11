## MODIFIED Requirements

### Requirement: --no-menu flag enables headless daemon mode
Daemon SHALL treat `--no-menu` as a deprecated unsupported flag in daemon mode and SHALL fail fast instead of silently ignoring it.

#### Scenario: Legacy no-menu flag is rejected
- **WHEN** user runs `startwatch daemon --no-menu`
- **THEN** CLI exits non-zero
- **AND** stderr contains `unknown flag: --no-menu`

#### Scenario: Daemon command without legacy flag
- **WHEN** user runs `startwatch daemon`
- **THEN** daemon starts headless runtime
- **AND** no menu-agent spawn is attempted by daemon runtime

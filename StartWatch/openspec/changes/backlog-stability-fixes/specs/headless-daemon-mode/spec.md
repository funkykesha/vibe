## ADDED Requirements

### Requirement: Daemon checks for .app existence before spawn
System SHALL check if `/Applications/StartWatchMenu.app` exists before attempting to spawn menu agent, and skip if absent.

#### Scenario: .app exists — spawn menu agent
- **WHEN** daemon starts and `/Applications/StartWatchMenu.app` exists
- **THEN** system executes `open -na /Applications/StartWatchMenu.app`

#### Scenario: .app missing — skip silently
- **WHEN** daemon starts in debug build without installed .app
- **THEN** system checks file existence, skips spawn, logs `[Daemon] Menu agent app not found, skipping`

#### Scenario: .app missing and no-menu flag
- **WHEN** daemon started with `--no-menu` flag
- **THEN** system skip all spawn attempts regardless of .app existence

### Requirement: --no-menu flag enables headless daemon mode
Daemon SHALL accept `--no-menu` flag and not attempt to spawn menu agent when present.

#### Scenario: Daemon with --no-menu flag
- **WHEN** user runs `./startwatch daemon --no-menu`
- **THEN** daemon starts but never attempts menu agent spawn

#### Scenario: Daemon without --no-menu flag
- **WHEN** user runs `./startwatch daemon`
- **THEN** daemon follows normal spawn behavior (check .app existence)

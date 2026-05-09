## ADDED Requirements

### Requirement: Refactor documentation SHALL describe runtime contracts
The change SHALL update or create documentation for architecture, IPC protocol, installer behavior, migration, and troubleshooting.

#### Scenario: Architecture documentation
- **WHEN** docs are updated
- **THEN** `docs/architecture.md` describes role separation, one build artifact with two installed copies, and AppKit boundary rules

#### Scenario: IPC protocol documentation
- **WHEN** docs are updated
- **THEN** `docs/IPC_PROTOCOL.md` describes raw JSON request/response shapes and states that PR1-6 has no subscribe or length-prefix framing

#### Scenario: Installer documentation
- **WHEN** docs are updated
- **THEN** `docs/INSTALLER.md` describes `/usr/local/bin/startwatch` as Mach-O, `/Applications/StartWatchMenu.app`, LaunchAgent keys, exit-code behavior, and socket permissions

#### Scenario: Migration documentation
- **WHEN** docs are updated
- **THEN** `docs/MIGRATION.md` documents breaking CLI, config, IPC, wrapper-removal, and autostart behavior changes

#### Scenario: Troubleshooting documentation
- **WHEN** docs are updated
- **THEN** `docs/TROUBLESHOOTING.md` explains stale socket recovery, launchd permissions, daemon offline recovery, and `launchctl kickstart`

### Requirement: Project agent notes SHALL match new runtime model
Project-local agent notes SHALL not instruct future work to use the old bundle-binary LaunchAgent model.

#### Scenario: Notes updated
- **WHEN** project notes are reviewed
- **THEN** any statement that LaunchAgent must run the bundle binary is replaced with the `/usr/local/bin/startwatch daemon` contract

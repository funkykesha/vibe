## ADDED Requirements

### Requirement: Force-stop signals SHALL not redefine clean exit behavior
Signals used during force stop SHALL be recovery behavior for unresponsive daemon processes and SHALL NOT change normal clean quit semantics.

#### Scenario: Normal quit unchanged

- **WHEN** user runs `startwatch quit` without `--force`
- **THEN** CLI requests daemon shutdown over IPC
- **AND** CLI does not send `SIGTERM` or `SIGKILL`

#### Scenario: Force quit preserves graceful path

- **WHEN** user runs `startwatch quit --force`
- **THEN** CLI first requests daemon shutdown over IPC when IPC is available
- **AND** CLI verifies daemon PID is no longer alive via `kill(pid, 0)` before declaring graceful success
- **AND** CLI does not send `SIGTERM` or `SIGKILL` if graceful success is verified

#### Scenario: Forced signal path is not clean quit

- **WHEN** force stop sends `SIGTERM` or `SIGKILL`
- **THEN** launchd MAY treat daemon termination as abnormal
- **AND** restart is governed by LaunchAgent failure restart semantics

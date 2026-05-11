## ADDED Requirements

### Requirement: Direct Python is debug-only
The system SHALL keep direct Python execution available only for local debug and diagnostics and SHALL NOT document it as a supported day-to-day install or launch path.

#### Scenario: Documentation separates debug launch
- **WHEN** user-facing documentation describes normal WorkGuard launch
- **THEN** it names `/Applications/WorkGuard.app` as the supported GUI target
- **THEN** any direct `conda run -n workguard python3 work_guard.py` command is labeled as debug or diagnostics only

### Requirement: Single instance applies to debug launch
The system SHALL keep the existing single-instance lock authoritative across installed app launches and direct debug launches.

#### Scenario: Debug launch does not duplicate running app
- **WHEN** WorkGuard is already running from `/Applications/WorkGuard.app`
- **WHEN** the operator starts WorkGuard through direct Python for debugging
- **THEN** `~/.config/work_guard/work_guard.lock` still contains the original running WorkGuard process id
- **THEN** process inspection shows only one active `work_guard.py` core process

#### Scenario: Installed app does not duplicate debug launch
- **WHEN** WorkGuard is already running through direct Python for debugging
- **WHEN** the operator opens `/Applications/WorkGuard.app`
- **THEN** `~/.config/work_guard/work_guard.lock` still contains the original running WorkGuard process id
- **THEN** process inspection shows only one active `work_guard.py` core process

## ADDED Requirements

### Requirement: Daemon returns terminal intent for interactive service control
For `startService` and `restartService`, when service `background` is not `true`, daemon SHALL return `executeInTerminal` response containing `TerminalCommand` with `serviceName` and executable command string.

#### Scenario: Interactive start returns terminal command
- **WHEN** client sends `startService` for a service with `background` unset or `false`
- **THEN** daemon responds with `executeInTerminal(TerminalCommand)` and does not launch terminal directly

#### Scenario: Interactive restart returns terminal command
- **WHEN** client sends `restartService` for a service with `background` unset or `false`
- **THEN** daemon responds with `executeInTerminal(TerminalCommand)` and does not launch terminal directly

### Requirement: Menu-agent executes terminal intent on main thread
When menu-agent receives `executeInTerminal`, it SHALL dispatch terminal execution to main thread before calling terminal-launch APIs.

#### Scenario: Menu Start action handles terminal intent safely
- **WHEN** menu-agent receives `executeInTerminal` from daemon callback path
- **THEN** menu-agent schedules `TerminalLauncher.open(...)` on `DispatchQueue.main`

### Requirement: CLI interactive start stays in current terminal
CLI start/restart for interactive services SHALL execute in current terminal session and SHALL NOT open a new terminal application window.

#### Scenario: CLI start interactive service
- **WHEN** user runs `startwatch start redis` and `background` is not `true`
- **THEN** CLI runs service command via `ServiceRunner.exec(...)` in current terminal

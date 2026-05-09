## ADDED Requirements

### Requirement: Runtime role SHALL be selected by launch context
The process SHALL select exactly one runtime role from launch context before any socket ownership or IPC logic runs.

#### Scenario: App bundle launch runs menu agent
- **WHEN** the executable is running from a `.app` bundle
- **THEN** the process starts Menu Agent behavior
- **AND** it does not start daemon runtime or CLI command routing

#### Scenario: Daemon argument runs headless daemon
- **WHEN** the executable is not running from a `.app` bundle
- **AND** the first argument is `daemon`
- **THEN** the process starts headless daemon runtime
- **AND** it does not start Menu Agent behavior

#### Scenario: Empty non-bundle invocation routes to status
- **WHEN** `/usr/local/bin/startwatch` is invoked with no arguments
- **THEN** the process routes to CLI status behavior
- **AND** it does not start Menu Agent behavior

### Requirement: Installed CLI binary SHALL not be an app-bundle wrapper
The installed `/usr/local/bin/startwatch` SHALL be the real Mach-O build artifact, not a wrapper that execs the app-bundle binary.

#### Scenario: Installer overwrites old wrapper
- **WHEN** `install.sh` installs StartWatch
- **THEN** any previous wrapper at `/usr/local/bin/startwatch` is replaced by the release Mach-O binary

#### Scenario: CLI commands are not app-bundle routed
- **WHEN** user runs `/usr/local/bin/startwatch status`
- **THEN** `isAppBundle` is false
- **AND** the command routes through CLI behavior

### Requirement: Daemon runtime SHALL respect AppKit boundary
Daemon runtime and core runtime files SHALL not import AppKit or instantiate AppKit UI APIs.

#### Scenario: Static boundary check passes
- **WHEN** the boundary check scans daemon/core runtime files
- **THEN** it finds no `import AppKit`, `NSApplication`, `NSStatusItem`, `NSWorkspace`, or `UNUserNotificationCenter` usage
- **AND** it finds no daemon/core reference to `TerminalLauncher`

#### Scenario: CLI may use terminal launcher
- **WHEN** CLI receives `executeInTerminal`
- **THEN** CLI may call shared `TerminalLauncher`
- **AND** daemon runtime remains uninvolved in terminal launch

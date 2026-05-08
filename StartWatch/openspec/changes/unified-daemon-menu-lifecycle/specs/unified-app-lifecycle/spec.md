## ADDED Requirements

### Requirement: Daemon ownership SHALL be determined by socket bind result
The system SHALL determine daemon ownership by attempting IPC socket bind/listen, not by a pre-check-only socket existence flow.

#### Scenario: Process becomes owner when bind succeeds
- **WHEN** process starts and IPC socket bind/listen succeeds
- **THEN** process becomes daemon owner
- **AND** it is allowed to bootstrap local daemon coordinator

#### Scenario: Process becomes non-owner on `EADDRINUSE`
- **WHEN** IPC socket bind fails with `EADDRINUSE`
- **THEN** process treats daemon ownership as already taken
- **AND** it follows non-owner startup path

#### Scenario: Stale socket is recovered safely
- **WHEN** bind fails with `EADDRINUSE` and daemon handshake/connection fails
- **THEN** process removes stale socket once and retries bind once
- **AND** on retry failure it falls back to non-owner behavior

### Requirement: Startup SHALL follow role-driven matrix
The system SHALL choose runtime mode based on ownership result and `showMenu` flag.

#### Scenario: Owner with menu starts full local mode
- **WHEN** process is owner and `showMenu=true`
- **THEN** local daemon coordinator and menu UI start in same process

#### Scenario: Owner without menu starts headless mode
- **WHEN** process is owner and `showMenu=false`
- **THEN** local daemon coordinator starts without menu UI

#### Scenario: Non-owner without menu exits as duplicate daemon
- **WHEN** process is non-owner and `showMenu=false`
- **THEN** process exits cleanly without starting second daemon

#### Scenario: Non-owner with menu starts UI client mode
- **WHEN** process is non-owner and `showMenu=true`
- **THEN** process starts menu UI without local daemon coordinator
- **AND** menu connects to existing daemon over IPC client

### Requirement: Menu control SHALL be abstracted for local and remote ownership
The system SHALL provide one menu control interface with local and remote implementations so menu actions do not depend on ownership mode.

#### Scenario: Local control implementation
- **WHEN** menu runs in owner process
- **THEN** control actions call local coordinator directly

#### Scenario: Remote control implementation
- **WHEN** menu runs in non-owner client mode
- **THEN** control actions send IPC commands to owner daemon

### Requirement: Quit semantics SHALL be equivalent across entrypoints
The system SHALL enforce same full shutdown effect for menu Quit and CLI stop.

#### Scenario: Menu Quit in local owner mode
- **WHEN** user selects Quit in owner+UI mode
- **THEN** local coordinator performs full shutdown (services, scheduler, IPC, process)

#### Scenario: Menu Quit in remote client mode
- **WHEN** user selects Quit in non-owner UI client mode
- **THEN** menu sends `.quit` to owner daemon over IPC
- **AND** resulting daemon shutdown matches local Quit effect

#### Scenario: CLI stop uses same daemon quit path
- **WHEN** user runs `startwatch stop`
- **THEN** daemon receives quit command and executes the same shutdown path used by menu Quit

## ADDED Requirements

### Requirement: Public rebuild entrypoint
The system SHALL provide `bash rebuild.sh` as the only supported public install and rebuild entrypoint for WorkGuard.

#### Scenario: Operator rebuilds WorkGuard
- **WHEN** the operator runs `bash rebuild.sh` from the project root
- **THEN** the system performs the supported WorkGuard rebuild and install flow

#### Scenario: Legacy setup entrypoint is rejected
- **WHEN** the operator runs `bash setup.sh`
- **THEN** the system exits non-zero with a message directing the operator to `bash rebuild.sh`

### Requirement: Installed app target
The system SHALL install WorkGuard as `/Applications/WorkGuard.app` and SHALL NOT present a project-local `.app` as a supported runnable target.

#### Scenario: Rebuild installs app to Applications
- **WHEN** `bash rebuild.sh` completes successfully
- **THEN** `/Applications/WorkGuard.app` exists
- **THEN** `/Applications/WorkGuard.app/Contents/MacOS/WorkGuard` exists and is executable

#### Scenario: Project-local app is not supported
- **WHEN** rebuild documentation or command output describes how to launch WorkGuard
- **THEN** it names `/Applications/WorkGuard.app` as the supported GUI target
- **THEN** it does not name a repo-local `.app` as a supported launch target

### Requirement: Stable bundle identity
The installed WorkGuard app bundle SHALL use `com.agaibadulin.workguard` as its `CFBundleIdentifier`.

#### Scenario: Bundle identifier is stable
- **WHEN** `bash rebuild.sh` completes successfully
- **THEN** `/Applications/WorkGuard.app/Contents/Info.plist` has `CFBundleIdentifier` equal to `com.agaibadulin.workguard`

### Requirement: Packaging-only bundle assets
The system SHALL keep bundle templates, plist templates, icons, and install-time assets under packaging-only ownership rather than treating repository-local bundle files as runnable targets.

#### Scenario: Rebuild uses packaging assets
- **WHEN** `bash rebuild.sh` generates the installed app bundle
- **THEN** it reads app bundle templates from the packaging asset location
- **THEN** it writes the runnable app to `/Applications/WorkGuard.app`

### Requirement: Source-linked launcher generation
The system SHALL generate the installed app launcher using the conda Python interpreter resolved during rebuild and the source-root-relative `work_guard.py` path resolved from the `rebuild.sh` location.

#### Scenario: Rebuild resolves launcher paths
- **WHEN** `bash rebuild.sh` generates the app launcher
- **THEN** the launcher contains the resolved `workguard` conda environment Python path
- **THEN** the launcher contains the project `work_guard.py` path resolved from the rebuild script location

### Requirement: Shared conda discovery
The system SHALL keep conda discovery in a shared shell utility sourced by `rebuild.sh` instead of relying on legacy `setup.sh` content.

#### Scenario: Rebuild discovers conda through shared utility
- **WHEN** `bash rebuild.sh` needs the conda executable
- **THEN** it sources the shared conda discovery utility
- **THEN** it does not read or execute `setup.sh` for conda discovery

### Requirement: Rebuild installs runtime dependencies
The system SHALL install Python dependencies from `requirements.txt` through the resolved `workguard` conda environment during rebuild.

#### Scenario: Rebuild installs requirements
- **WHEN** `bash rebuild.sh` prepares the `workguard` conda environment
- **THEN** it installs `requirements.txt` using that environment
- **THEN** dependency installation does not require running `setup.sh`

### Requirement: Rebuild preserves optional Swift menu build
The system SHALL compile the optional Swift menu binary during rebuild when `swiftc` is available and the Swift menu source exists.

#### Scenario: Swift menu source can be built
- **WHEN** `swiftc` is available and `WorkGuardMenu/main.swift` exists
- **THEN** `bash rebuild.sh` builds the Swift menu binary used by the existing `WORKGUARD_SWIFT_MENU` behavior

#### Scenario: Swift menu source cannot be built
- **WHEN** `swiftc` is unavailable or `WorkGuardMenu/main.swift` is missing
- **THEN** `bash rebuild.sh` warns clearly
- **THEN** the existing non-Swift menu fallback behavior remains available

### Requirement: LaunchServices refresh
The system SHALL refresh LaunchServices during rebuild using `lsregister` before launching the installed app.

#### Scenario: Rebuild refreshes LaunchServices
- **WHEN** `/Applications/WorkGuard.app` is replaced during rebuild
- **THEN** the previous app registration is unregistered with `lsregister -u` when the previous app exists
- **THEN** the new app is force-registered with `lsregister -f /Applications/WorkGuard.app`
- **THEN** the rebuild does not rely on `lsregister -kill` (removed on recent macOS as unsafe)

### Requirement: Rebuild disk verification
The system SHALL expose deterministic disk-state verification checks for successful rebuild.

#### Scenario: Rebuild disk state can be verified
- **WHEN** `bash rebuild.sh` completes successfully
- **THEN** `/Applications/WorkGuard.app` exists
- **THEN** `/Applications/WorkGuard.app/Contents/MacOS/WorkGuard` exists and is executable
- **THEN** `/Applications/WorkGuard.app/Contents/Info.plist` has `CFBundleIdentifier` equal to `com.agaibadulin.workguard`
- **THEN** `codesign --verify --deep --strict /Applications/WorkGuard.app` succeeds

### Requirement: Rebuild runtime verification
The system SHALL expose deterministic runtime verification checks after the rebuilt app is launched.

#### Scenario: Rebuild runtime state can be verified
- **WHEN** `bash rebuild.sh` completes successfully and the launched WorkGuard process starts
- **THEN** `/Applications/WorkGuard.app` can be opened
- **THEN** `~/.config/work_guard/work_guard.lock` contains the running WorkGuard process id
- **THEN** WorkGuard writes a fresh startup entry to `~/.config/work_guard/work_guard.log`

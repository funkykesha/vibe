## ADDED Requirements

### Requirement: Ritual-first finance product
The system SHALL be organized around salary day, quick capital refresh, progress check, and model maintenance rituals.

#### Scenario: Salary day starts
- **WHEN** the user performs a salary-day workflow
- **THEN** the system SHALL support salary calculation, distribution review, balance update context, and optional snapshot creation

#### Scenario: Progress is reviewed
- **WHEN** the user reviews current financial progress
- **THEN** the system SHALL show current capital context and movement against available explicit snapshots

### Requirement: Surface responsibility split
The dashboard and Telegram assistant SHALL be complementary surfaces over shared financial state.

#### Scenario: Dashboard is used
- **WHEN** the user needs detailed review or model maintenance
- **THEN** the dashboard SHALL own salary details, capital details, history, and settings

#### Scenario: Telegram is used
- **WHEN** the user needs a quick mobile action
- **THEN** Telegram SHALL own summaries, safe manual updates, snapshots, and later guided provider flows

### Requirement: Shared source of truth
The product SHALL treat accounts, settings, salary events, snapshots, and provider mappings as shared state.

#### Scenario: State changes from one surface
- **WHEN** a supported surface changes shared financial state
- **THEN** other supported surfaces SHALL read the updated state without relying on browser-only persistence

### Requirement: Single-user boundary
The system SHALL optimize for one configured personal user and SHALL NOT introduce a multi-user account model.

#### Scenario: Trusted local access
- **WHEN** the app runs locally for the configured user
- **THEN** financial data SHALL be treated as belonging to that one user

#### Scenario: Deployed access
- **WHEN** the app is deployed beyond localhost
- **THEN** the implementation SHALL define lightweight access controls appropriate for the trusted single-user boundary

### Requirement: Salary event semantics
The system SHALL treat saved salary calculations as salary event records.

#### Scenario: Salary calculation is saved
- **WHEN** the user saves a salary calculation
- **THEN** the record SHALL preserve event date, event type, gross amount, deductions, net amount, and distribution

### Requirement: Snapshot semantics
The system SHALL treat snapshots as explicit financial checkpoints with captured interpretation context.

#### Scenario: Snapshot is created
- **WHEN** the user creates a snapshot
- **THEN** the snapshot SHALL capture current account balances, relevant settings, timestamp or label, and calculated totals

#### Scenario: Balance is edited without snapshot
- **WHEN** the user edits current account state without requesting a snapshot
- **THEN** the system SHALL NOT create a historical checkpoint implicitly

## ADDED Requirements

### Requirement: Shared account state
The system SHALL maintain account balances in a shared persisted state used by dashboard, Telegram bot, and supported integrations.

#### Scenario: Account update visible everywhere
- **WHEN** an account balance is changed through any supported surface
- **THEN** the updated balance SHALL be visible through all other supported surfaces without relying on browser-local state

### Requirement: Shared settings state
The system SHALL maintain finance settings in a shared persisted state.

#### Scenario: Settings update affects future calculations
- **WHEN** the user changes categories, deductions, USD rate, or mortgage balance
- **THEN** future salary distributions, capital totals, summaries, and snapshots SHALL use the updated settings

### Requirement: Salary event records
The system SHALL store saved salary calculations as salary event records.

#### Scenario: Save salary event
- **WHEN** the user saves a salary calculation
- **THEN** the system SHALL persist event date, event type, gross amount, deductions, net amount, and distribution

### Requirement: Single-user trusted boundary
The system SHALL optimize for one authorized personal user and SHALL NOT require a multi-user account model.

#### Scenario: Access from trusted surfaces
- **WHEN** the dashboard, bot, or backend uses financial data
- **THEN** the system SHALL treat the data as belonging to the single configured user and enforce only the lightweight access controls needed for that context

### Requirement: External account mapping
The system SHALL preserve mappings between internal accounts and supported external providers.

#### Scenario: Sync mapped account
- **WHEN** an external provider returns a balance for a mapped account
- **THEN** the system SHALL update the matching internal account without changing unrelated accounts

#### Scenario: Unmapped external account
- **WHEN** an external provider returns an account that is not mapped
- **THEN** the system SHALL report the unmapped account and SHALL NOT merge it silently into an existing account

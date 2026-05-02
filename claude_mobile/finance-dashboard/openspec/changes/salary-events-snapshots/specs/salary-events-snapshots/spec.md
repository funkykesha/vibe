## ADDED Requirements

### Requirement: Salary event records
The system SHALL persist saved salary calculations as salary event records.

#### Scenario: Save salary event
- **WHEN** the user explicitly saves a salary calculation
- **THEN** the system SHALL store event date, event type, gross amount, deductions, net amount, and distribution

### Requirement: Explicit snapshots
The system SHALL create capital history only through explicit snapshots.

#### Scenario: Snapshot requested
- **WHEN** the user requests a snapshot
- **THEN** the system SHALL create a historical checkpoint from current financial state

#### Scenario: Account edit only
- **WHEN** the user edits an account balance without requesting a snapshot
- **THEN** the system SHALL update current state without creating a snapshot

### Requirement: Captured snapshot context
Each snapshot SHALL capture the settings and context needed to interpret historical totals.

#### Scenario: Snapshot is saved
- **WHEN** a snapshot is saved
- **THEN** it SHALL include account balances, categories, currencies, USD rate, mortgage value, timestamp or label, and payload version

### Requirement: Snapshot totals
Each snapshot SHALL provide key calculated totals.

#### Scenario: Snapshot is displayed
- **WHEN** a snapshot is displayed
- **THEN** the system SHALL provide full capital, capital excluding debts, category totals, currency-adjusted totals, and mortgage-adjusted position

### Requirement: Snapshot comparison
The system SHALL compare two snapshots.

#### Scenario: Compare snapshots
- **WHEN** the user or API compares two snapshots
- **THEN** the system SHALL report deltas for key totals and categories

### Requirement: History readiness without import
The snapshot workflow SHALL work without historical spreadsheet import.

#### Scenario: No historical import exists
- **WHEN** the user creates new app snapshots
- **THEN** the system SHALL support timeline and comparison behavior from those app-created snapshots

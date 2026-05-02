## ADDED Requirements

### Requirement: Explicit capital snapshots
The system SHALL create capital history through explicit snapshots initiated by the user or a confirmed ritual step.

#### Scenario: Create snapshot
- **WHEN** the user creates a snapshot
- **THEN** the system SHALL save current account balances, key settings needed for interpretation, and a timestamp or user-visible label

#### Scenario: Avoid implicit edit snapshots
- **WHEN** the user edits an account balance or setting without requesting a snapshot
- **THEN** the system SHALL update current state without creating a historical checkpoint

### Requirement: Snapshot totals
The system SHALL calculate key totals for every snapshot.

#### Scenario: Calculate snapshot summary
- **WHEN** a snapshot is created or displayed
- **THEN** the system SHALL provide full capital, capital excluding debts, category totals, currency-adjusted totals, and mortgage-adjusted position

### Requirement: Snapshot comparison
The system SHALL support comparison between snapshots.

#### Scenario: Compare two snapshots
- **WHEN** the user compares two snapshots
- **THEN** the system SHALL show the delta for key capital totals and categories

### Requirement: Progress context
The system SHALL present capital history as progress context rather than raw ledger data only.

#### Scenario: Show movement direction
- **WHEN** the user reviews history
- **THEN** the system SHALL make it clear whether capital and mortgage-adjusted position moved up, down, or stayed approximately flat

### Requirement: Historical import boundary
The system SHALL treat historical spreadsheet import as optional and separate from the core snapshot workflow.

#### Scenario: No historical import configured
- **WHEN** no historical spreadsheet import has been performed
- **THEN** the system SHALL still support new snapshots from the current app state

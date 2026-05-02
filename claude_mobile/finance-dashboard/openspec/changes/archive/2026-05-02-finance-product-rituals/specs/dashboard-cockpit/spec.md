## ADDED Requirements

### Requirement: Dashboard salary cockpit
The dashboard SHALL provide a full-screen salary cockpit for careful salary distribution review.

#### Scenario: Review salary distribution
- **WHEN** the user opens the salary area
- **THEN** the dashboard SHALL show salary inputs, deductions, category percentages, calculated net salary, and category distribution

#### Scenario: Export salary plan
- **WHEN** the user chooses to copy or share the salary distribution
- **THEN** the dashboard SHALL produce a human-readable distribution plan suitable for manual transfers or record keeping

### Requirement: Dashboard capital cockpit
The dashboard SHALL provide a capital cockpit that shows accounts, banks, categories, currencies, and totals in one place.

#### Scenario: Review accounts by bank
- **WHEN** the user opens the capital area
- **THEN** the dashboard SHALL group accounts by bank and show account name, type, category, balance, and currency-adjusted value

#### Scenario: Review capital totals
- **WHEN** account balances or settings change
- **THEN** the dashboard SHALL recalculate full capital, capital excluding debts, category totals, investment totals, and mortgage-adjusted position

### Requirement: Dashboard history cockpit
The dashboard SHALL provide a history cockpit for reviewing saved capital checkpoints.

#### Scenario: Review timeline
- **WHEN** the user opens the history area
- **THEN** the dashboard SHALL show saved snapshots in chronological order with key totals

#### Scenario: Inspect snapshot delta
- **WHEN** the user selects a snapshot for comparison
- **THEN** the dashboard SHALL show how capital and category totals changed from the comparison snapshot

### Requirement: Dashboard settings cockpit
The dashboard SHALL provide settings controls for maintaining the financial model.

#### Scenario: Edit financial model
- **WHEN** the user opens settings
- **THEN** the dashboard SHALL allow editing categories, deductions, accounts, currencies, USD rate, mortgage balance, and external account mappings where available

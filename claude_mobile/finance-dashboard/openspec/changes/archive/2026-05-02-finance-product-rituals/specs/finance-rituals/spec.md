## ADDED Requirements

### Requirement: Salary day ritual
The system SHALL support a salary day ritual that turns a salary event into a distribution plan, balance update checkpoint, and optional capital snapshot.

#### Scenario: Regular salary calculation
- **WHEN** the user starts a salary ritual for the 5th or 20th day and provides gross salary inputs
- **THEN** the system SHALL calculate net salary after configured deductions and show the distribution across configured categories

#### Scenario: Salary event checkpoint
- **WHEN** the user finishes reviewing a salary calculation
- **THEN** the system SHALL allow the user to save the calculation as a salary event for future reference

### Requirement: Quick capital refresh ritual
The system SHALL support a quick capital refresh ritual for bringing current balances into the shared financial state.

#### Scenario: Refresh automated accounts
- **WHEN** the user requests an automated refresh
- **THEN** the system SHALL update supported automated accounts and report which balances changed

#### Scenario: Update manual account
- **WHEN** the user manually updates a non-automated account balance
- **THEN** the system SHALL save the new balance and make it visible to all product surfaces

### Requirement: Progress check ritual
The system SHALL support a progress check ritual that explains the current financial position and its movement over time.

#### Scenario: Review current financial position
- **WHEN** the user opens a progress view or requests a summary
- **THEN** the system SHALL show current capital, capital excluding debts, mortgage-adjusted position, and category totals

#### Scenario: Compare against previous checkpoint
- **WHEN** at least two snapshots exist
- **THEN** the system SHALL show the change between the selected snapshot and a previous snapshot

### Requirement: Model maintenance ritual
The system SHALL support maintenance of the financial model used by salary and capital rituals.

#### Scenario: Update distribution model
- **WHEN** the user changes salary categories, percentages, deductions, account categories, currency, USD rate, or mortgage balance
- **THEN** the system SHALL persist the updated model for future calculations and summaries

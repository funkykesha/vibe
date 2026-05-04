# dashboard-api-migration Specification

## Purpose
TBD - created by archiving change dashboard-api-migration. Update Purpose after archive.
## Requirements
### Requirement: API-backed initial read
The dashboard SHALL read accounts and settings from backend APIs on startup after migration.

#### Scenario: Backend has data
- **WHEN** the dashboard starts and the backend returns accounts/settings
- **THEN** the dashboard SHALL render from backend data
- **AND** SHALL NOT treat localStorage as fresher source-of-truth data

### Requirement: localStorage import path
The dashboard SHALL provide an explicit path for importing compatible existing localStorage data when backend state is empty.

#### Scenario: Existing localStorage data is found
- **WHEN** backend state is empty and compatible `fin-v3` data exists
- **THEN** the dashboard SHALL allow an explicit import rather than silently overwriting backend state

### Requirement: Partial writes
The dashboard SHALL use API writes that update only the intended financial fields.

#### Scenario: Account balance changes
- **WHEN** the user changes one account balance
- **THEN** the dashboard SHALL persist that account update without replacing unrelated accounts from stale client state

#### Scenario: One setting changes
- **WHEN** the user changes one settings field
- **THEN** the dashboard SHALL preserve other settings fields

### Requirement: Loading and error states
The dashboard SHALL show accurate loading and error states for API reads and writes.

#### Scenario: Startup read fails
- **WHEN** accounts/settings cannot be loaded
- **THEN** the dashboard SHALL show an error or retry state instead of presenting stale values as current

#### Scenario: Save fails
- **WHEN** an API write fails
- **THEN** the dashboard SHALL communicate that the change was not saved

### Requirement: Fetch race handling
The dashboard SHALL protect against stale API responses overwriting newer state.

#### Scenario: Requests complete out of order
- **WHEN** an older request returns after a newer request
- **THEN** the older response SHALL NOT overwrite newer dashboard state

### Requirement: Calculation preservation
The migration SHALL preserve existing salary and capital calculations.

#### Scenario: Same inputs after migration
- **WHEN** the same categories, deductions, accounts, USD rate, mortgage, and salary inputs are used
- **THEN** calculated salary distribution and capital totals SHALL match the pre-migration behavior


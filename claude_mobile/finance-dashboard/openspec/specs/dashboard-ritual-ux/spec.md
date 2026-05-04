# dashboard-ritual-ux Specification

## Purpose
TBD - created by archiving change dashboard-ritual-ux. Update Purpose after archive.
## Requirements
### Requirement: Theme modes
The dashboard SHALL support `System`, `Light`, and `Dark` theme modes through shared semantic tokens.

#### Scenario: Theme changes
- **WHEN** the user changes theme mode
- **THEN** colors and surfaces SHALL update
- **AND** layout and information hierarchy SHALL remain unchanged

### Requirement: Compact top navigation
The dashboard SHALL provide compact navigation for `Ритуалы`, `Капитал`, `История`, and `Настройки`.

#### Scenario: Dashboard opens
- **WHEN** the user opens the dashboard
- **THEN** `Ритуалы` SHALL be the default section

### Requirement: Ritual first screen
The `Ритуалы` section SHALL show `Зарплатный день` as the primary MVP workflow.

#### Scenario: Salary ritual is visible
- **WHEN** the ritual screen is displayed
- **THEN** salary input, deductions, distribution, capital update status, and snapshot step SHALL be visible in one workspace

### Requirement: Compact capital context
The ritual screen SHALL show a compact capital strip without replacing the salary workflow.

#### Scenario: Capital context is shown
- **WHEN** the user reviews salary-day context
- **THEN** the screen SHALL show key capital values from current derived totals
- **AND** SHALL NOT show history charts in the ritual header

### Requirement: History shell
The dashboard SHALL provide a history shell that depends on reliable snapshots.

#### Scenario: Snapshot data is unavailable
- **WHEN** no snapshot API or reliable snapshot data exists
- **THEN** the history screen SHALL show an empty or unavailable state instead of invented chart data

### Requirement: Settings shell
The dashboard SHALL provide a settings shell for model maintenance.

#### Scenario: User opens settings
- **WHEN** the user opens `Настройки`
- **THEN** the dashboard SHALL expose categories, deductions, accounts, currency, USD rate, and mortgage maintenance according to available implementation state

### Requirement: Responsive layout
The dashboard SHALL use a two-column desktop ritual workspace and a single-column mobile flow.

#### Scenario: Desktop viewport
- **WHEN** the viewport has desktop width
- **THEN** primary salary work and secondary status/actions SHALL be arranged in two columns

#### Scenario: Mobile viewport
- **WHEN** the viewport has mobile width
- **THEN** the same content SHALL be readable in one vertical flow without horizontal scrolling


## ADDED Requirements

### Requirement: Ritual-first landing section
The dashboard SHALL open on a `Ритуалы` section where the salary-day ritual is the primary MVP workflow.

#### Scenario: User opens dashboard
- **WHEN** the user opens the dashboard
- **THEN** the first visible workflow is `Зарплатный день`
- **AND** the screen shows what action is needed next in the ritual

### Requirement: Compact capital context
The ritual screen SHALL show a compact capital strip with key capital values without replacing the salary-day workflow as the primary focus.

#### Scenario: User reviews salary-day context
- **WHEN** the salary-day ritual screen is visible
- **THEN** the screen shows compact values for capital fact, capital with debts, fast reserves, family capital, son capital, and mortgage context
- **AND** the screen does not show charts in the ritual header area

### Requirement: Visible salary-day steps
The salary-day ritual SHALL be presented as one workspace with visible steps instead of a wizard.

#### Scenario: User completes salary day
- **WHEN** the user works through salary day
- **THEN** the workspace shows the steps for salary input, deductions, distribution, capital update, and snapshot
- **AND** the user can inspect the main salary inputs and distribution without navigating through separate wizard pages

### Requirement: Responsive layout
The design SHALL use a two-column desktop workspace and a single-column mobile flow.

#### Scenario: User opens dashboard on desktop
- **WHEN** the viewport has desktop width
- **THEN** salary inputs and distribution appear in the main work area
- **AND** status, key numbers, and finish actions appear in a secondary column

#### Scenario: User opens dashboard on mobile
- **WHEN** the viewport has mobile width
- **THEN** the same content appears as a single top-to-bottom flow
- **AND** the content does not require horizontal scrolling

### Requirement: Theme modes
The design SHALL support `System`, `Light`, and `Dark` theme modes.

#### Scenario: User changes theme preference
- **WHEN** the user selects `System`, `Light`, or `Dark`
- **THEN** the dashboard applies the selected theme mode
- **AND** the layout and information hierarchy remain unchanged

### Requirement: Primary Swiss Finance theme
The primary light theme SHALL use a Swiss Finance visual language with strict layout, neutral surfaces, graphite text, hairline borders, and one restrained accent color.

#### Scenario: Light theme is active
- **WHEN** the dashboard is in light theme
- **THEN** the interface uses light neutral or paper-like surfaces
- **AND** it avoids decorative gradients, heavy shadows, and card-heavy composition

### Requirement: Secondary Dark Finance theme
The dark theme SHALL use a financial cockpit visual language and SHALL NOT preserve the current terminal-like mono aesthetic as the main style.

#### Scenario: Dark theme is active
- **WHEN** the dashboard is in dark theme
- **THEN** the interface uses deep neutral surfaces, high-contrast text, and the same component structure as light theme
- **AND** body text is not globally mono-styled

### Requirement: Compact top navigation
The dashboard SHALL provide compact top navigation for `Ритуалы`, `Капитал`, `История`, and `Настройки`.

#### Scenario: User navigates between product areas
- **WHEN** the user uses the top navigation
- **THEN** the user can move between rituals, capital, history, and settings
- **AND** `Ритуалы` remains the default section for the MVP

### Requirement: History charts deferred from first ritual screen
The first ritual screen SHALL NOT include history charts, while the product design SHALL reserve a separate history area for future charts and progress review.

#### Scenario: User opens salary-day ritual
- **WHEN** the salary-day ritual is visible
- **THEN** no capital history chart is shown on the first ritual screen

#### Scenario: Snapshot history exists
- **WHEN** reliable snapshot history is available
- **THEN** the `История` section can show capital trend, deltas, and snapshot review

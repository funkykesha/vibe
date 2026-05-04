## ADDED Requirements

### Requirement: Deduction mapping configuration
The system SHALL maintain a `deductionMapping` object that maps each deduction key (`ndfl`, `dms`, `insurance`, `overspend`) to a category id. Default values: `ndfl→13` (На себя), `dms→7` (Здоровье), `insurance→7` (Здоровье), `overspend→10` (Свободный поток).

#### Scenario: Default mapping applied on first load
- **WHEN** localStorage contains no `deductionMapping` key
- **THEN** the system SHALL apply default mapping values without user action

#### Scenario: Mapping persisted on change
- **WHEN** user changes a mapping dropdown in Settings
- **THEN** the updated mapping SHALL be saved to localStorage under `fin-v3`

### Requirement: Deduction mapping UI in Settings
The Settings tab SHALL display a table with one row per deduction (НДФЛ, ДМС Тани, Страховка, Перерасход). Each row SHALL have a dropdown listing all available categories.

#### Scenario: User reassigns deduction to category
- **WHEN** user selects a different category in the НДФЛ row dropdown
- **THEN** the distribution table SHALL immediately reflect the new "потрачено" value for that category

### Requirement: Distribution table shows spent and available
The distribution table SHALL show three numeric values per category row: "Выделено" (floor allocation), "Потрачено" (sum of deductions mapped to this category), and "Доступно" (Выделено − Потрачено).

#### Scenario: Category with mapped deductions
- **WHEN** ДМС Тани (1601.72) and Страховка (203.84) are both mapped to Здоровье
- **THEN** Здоровье row SHALL show Потрачено = 1805.56 and Доступно = Выделено − 1805.56

#### Scenario: Доступно is negative
- **WHEN** Потрачено exceeds Выделено for a category
- **THEN** Доступно SHALL be displayed in red color

#### Scenario: Category with no mapped deductions
- **WHEN** no deductions are mapped to a category
- **THEN** Потрачено SHALL display "—" and Доступно SHALL equal Выделено

### Requirement: НДФЛ calculated from badge
The system SHALL calculate НДФЛ as `parse(badge) * 0.13`. This value SHALL be read-only and displayed in the deductions section.

#### Scenario: Badge input changes НДФЛ
- **WHEN** user enters 30000 in the Бейдж field
- **THEN** НДФЛ SHALL display 3900.00 (read-only)

#### Scenario: Empty badge yields zero НДФЛ
- **WHEN** Бейдж field is empty
- **THEN** НДФЛ SHALL display 0 and not affect totalDeds

### Requirement: Floor rounding for all categories except На себя
All category allocations except "На себя" (id=13) SHALL be calculated as `Math.floor(net * pct / 100)`. "На себя" SHALL equal `net − sum(all other floor amounts)`.

#### Scenario: Rounding leaves remainder in На себя
- **WHEN** net = 93194 and category percents produce fractional amounts
- **THEN** На себя SHALL absorb any fractional remainder so that sum of all amounts equals net exactly

#### Scenario: На себя percent not editable
- **WHEN** user views the Settings categories list
- **THEN** the % input for category id=13 SHALL be hidden or disabled; a label "остаток" SHALL appear instead

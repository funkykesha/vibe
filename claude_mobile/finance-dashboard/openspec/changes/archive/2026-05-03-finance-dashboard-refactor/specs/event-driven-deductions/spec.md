## ADDED Requirements

### Requirement: Single event type field replaces dual pay-day controls
The system SHALL use only `salaryEventType` dropdown to determine the payment date. The `payDay` state variable and "5-е/20-е" buttons SHALL be removed. The day used in the ISO event date SHALL be derived: `5th_payday→5`, `20th_payday→20`, all others→5.

#### Scenario: 5th payday selected
- **WHEN** user selects "5-е (зарплата)" in the event type dropdown
- **THEN** the ISO date constructed for the event SHALL use day=5

#### Scenario: 20th payday selected
- **WHEN** user selects "20-е (аванс)" in the event type dropdown
- **THEN** the ISO date constructed for the event SHALL use day=20

#### Scenario: Non-standard event type selected
- **WHEN** user selects "Отпускные", "Бонус", or "Прочее"
- **THEN** the ISO date SHALL use day=5 as default

### Requirement: Deductions auto-shown for 5th payday only
The deductions input block (Бейдж, ДМС Тани, Страховка Тани, Перерасход, НДФЛ read-only) SHALL be visible by default if and only if `salaryEventType === "5th_payday"`.

#### Scenario: 5th payday — deductions visible
- **WHEN** salaryEventType is "5th_payday"
- **THEN** the deductions block SHALL be rendered without any user action

#### Scenario: Other event type — deductions hidden
- **WHEN** salaryEventType is "20th_payday", "vacation", "bonus", or "other"
- **THEN** the deductions block SHALL be hidden and replaced with a "+ Вычеты" toggle button

#### Scenario: Manual toggle reveals deductions
- **WHEN** user clicks "+ Вычеты" on a non-5th event
- **THEN** the deductions block SHALL become visible and the toggle button SHALL disappear

### Requirement: Input fields for variable deductions in top block
The following editable inputs SHALL appear above the НДФЛ read-only row: Начислено (gross), Бейдж, ДМС Тани (default 1601.72), Страховка Тани (default 203.84), Перерасход.

#### Scenario: Default values pre-filled
- **WHEN** user opens the ritual form for the first time
- **THEN** ДМС Тани SHALL show 1601.72 and Страховка Тани SHALL show 203.84

#### Scenario: Changed values persist to localStorage
- **WHEN** user edits ДМС Тани amount
- **THEN** the new value SHALL be saved in `fin-v3` and restored on next load

### Requirement: Total deductions calculated from explicit fields
`totalDeds` SHALL equal `parse(badge)*0.13 + parse(dmsAmount) + parse(insAmount) + parse(overspend)`. The old `deds` array SHALL be removed from state.

#### Scenario: All fields filled
- **WHEN** badge=10000, dms=1601.72, ins=203.84, overspend=500
- **THEN** totalDeds SHALL equal 1300 + 1601.72 + 203.84 + 500 = 3605.56

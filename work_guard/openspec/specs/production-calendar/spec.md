## Purpose

Define production-calendar behavior for Russian working-day rules, including holidays, transferred workdays, and shortened days.

## Requirements

### Requirement: Russian production calendar source
The system SHALL support Russian production-calendar data from xmlcalendar.ru yearly JSON files.

#### Scenario: Calendar data is fetched for current year
- **WHEN** the app needs production-calendar data for a year that is not cached
- **THEN** it fetches `https://xmlcalendar.ru/data/ru/<year>/calendar.json`

#### Scenario: Cached calendar data is available
- **WHEN** calendar data for a year is present in the local cache
- **THEN** the app uses cached data without requiring network access during status calculation

#### Scenario: Calendar data unavailable
- **WHEN** neither network data nor cache data is available
- **THEN** the app falls back to configured `work_days` behavior and continues running

### Requirement: Production calendar day classification
The system SHALL classify dates using xmlcalendar.ru day markers before applying the weekly `work_days` fallback.

#### Scenario: Holiday marker
- **WHEN** the current date appears in xmlcalendar data without a suffix
- **THEN** the app treats the date as non-working regardless of configured `work_days`

#### Scenario: Transferred workday marker
- **WHEN** the current date appears in xmlcalendar data with a `+` suffix
- **THEN** the app treats the date as working regardless of configured `work_days`

#### Scenario: Shortened workday marker
- **WHEN** the current date appears in xmlcalendar data with a `*` suffix
- **THEN** the app treats the date as a working day with effective work end one hour earlier than configured `work_end`

#### Scenario: Date missing from calendar markers
- **WHEN** the current date does not appear in xmlcalendar data
- **THEN** the app uses configured `work_days` and normal work hours

### Requirement: Shortened workday end time
The system SHALL end shortened workdays one hour earlier than the configured normal work end.

#### Scenario: Normal end is 19:00
- **WHEN** the current date is a shortened workday and `work_end` is `19:00`
- **THEN** work time ends at `18:00`

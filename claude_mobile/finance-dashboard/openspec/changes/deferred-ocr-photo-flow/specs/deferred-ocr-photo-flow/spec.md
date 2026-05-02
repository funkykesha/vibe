## ADDED Requirements

### Requirement: OCR deferred from MVP
The system SHALL NOT require OCR/photo extraction for MVP finance rituals.

#### Scenario: Photo is received before OCR implementation
- **WHEN** a photo command or image is received before OCR is implemented
- **THEN** the system SHALL acknowledge that processing is unavailable
- **AND** SHALL NOT modify financial data

### Requirement: Candidate-only extraction
Future OCR/photo or historical import extraction SHALL produce reviewable candidates before writes.

#### Scenario: Extraction finds a possible balance
- **WHEN** future OCR extracts a candidate balance
- **THEN** the system SHALL present the candidate for review instead of writing it automatically

### Requirement: Manual confirmation before writes
Future OCR/photo and historical import flows SHALL require explicit confirmation before financial writes.

#### Scenario: User confirms candidate
- **WHEN** the user explicitly confirms a candidate balance or imported row
- **THEN** the system MAY write the confirmed data through the same safe update paths as manual edits

### Requirement: Historical import visibility
Historical import SHALL remain optional and separate from app-created snapshots.

#### Scenario: No historical import has run
- **WHEN** the user creates new app snapshots
- **THEN** snapshot history SHALL still work from app-created data

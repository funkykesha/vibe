## ADDED Requirements

### Requirement: Generated notes expose native review controls
The system SHALL include an Obsidian-native feedback section in each newly generated processed note.

#### Scenario: New note contains clickable feedback tasks
- **WHEN** the pipeline writes a new processed research note
- **THEN** the note body MUST contain unchecked markdown task checkboxes labeled `Прочитал` and `Взял`

#### Scenario: Feedback controls require no plugin
- **WHEN** the user opens the generated note in Obsidian Reading view
- **THEN** the feedback controls MUST be usable as native Obsidian markdown task checkboxes

### Requirement: Reviewed notes route to outcome folders
The system SHALL move reviewed notes out of the active processed queue according to the user's checkbox selections.

#### Scenario: Read and taken note is archived as taken
- **WHEN** a note has `Прочитал` checked and `Взял` checked
- **THEN** the system MUST move the note to `Research/Taken/`

#### Scenario: Read and not taken note is archived as skipped
- **WHEN** a note has `Прочитал` checked and `Взял` unchecked
- **THEN** the system MUST move the note to `Research/Skipped/`

#### Scenario: Unread note remains active
- **WHEN** a note has `Прочитал` unchecked
- **THEN** the system MUST keep the note in `Research/Processed/`

#### Scenario: Read checkbox controls routing priority
- **WHEN** a note has `Взял` checked and `Прочитал` unchecked
- **THEN** the system MUST keep the note in `Research/Processed/` and MUST NOT use it for calibration

### Requirement: Reviewed outcomes calibrate future scoring
The system SHALL use reviewed note outcomes as calibration context when scoring new research items.

#### Scenario: Taken notes become positive examples
- **WHEN** the system prepares to enrich new items
- **THEN** notes in `Research/Taken/` MUST be summarized as positive calibration examples

#### Scenario: Skipped notes become negative examples
- **WHEN** the system prepares to enrich new items
- **THEN** notes in `Research/Skipped/` MUST be summarized as negative calibration examples

#### Scenario: Unread notes are neutral
- **WHEN** a note remains unread in `Research/Processed/`
- **THEN** the system MUST NOT use the note as positive or negative calibration feedback

#### Scenario: Enrichment receives feedback context
- **WHEN** the system calls enrichment for a new item
- **THEN** the enrichment prompt MUST include a bounded summary of available positive and negative feedback examples

### Requirement: Duplicate detection covers all research outcome folders
The system SHALL consider processed, taken, and skipped notes when determining whether an incoming item already exists.

#### Scenario: Existing taken item is not reprocessed
- **WHEN** an incoming item has the same normalized key as a note in `Research/Taken/`
- **THEN** the item MUST be treated as an existing duplicate instead of being enriched as a new note

#### Scenario: Existing skipped item is not reprocessed
- **WHEN** an incoming item has the same normalized key as a note in `Research/Skipped/`
- **THEN** the item MUST be treated as an existing duplicate instead of being enriched as a new note

### Requirement: Digest represents the active triage queue
The system SHALL keep the main digest focused on currently unreviewed processed notes.

#### Scenario: Digest routes reviewed notes before regeneration
- **WHEN** the user runs digest regeneration without a full research run
- **THEN** the system MUST first route reviewed notes from `Research/Processed/` to `Research/Taken/` or `Research/Skipped/`
- **AND** the system MUST NOT fetch or enrich new items as part of digest-only routing

#### Scenario: Reviewed notes do not crowd digest
- **WHEN** the system regenerates the research inbox digest
- **THEN** the digest MUST list notes from `Research/Processed/` and MUST exclude notes already moved to `Research/Taken/` or `Research/Skipped/`

### Requirement: Old processed notes can be migrated to the review workflow
The system SHALL provide an additive migration path for processed notes that were generated before feedback controls existed.

#### Scenario: Migration adds missing review controls
- **WHEN** the user runs the old-note feedback migration
- **THEN** processed notes missing the feedback section MUST receive unchecked `Прочитал` and `Взял` markdown task checkboxes

#### Scenario: Migration does not infer outcomes
- **WHEN** the old-note feedback migration updates a note
- **THEN** the system MUST NOT move the note to `Research/Taken/` or `Research/Skipped/`
- **AND** the system MUST NOT treat the note as positive or negative calibration feedback until the user checks `Прочитал`

### Requirement: Feedback workflow is documented
The system SHALL document the checkbox meanings and reviewed-note folder workflow.

#### Scenario: User reads workflow documentation
- **WHEN** the user opens the project README
- **THEN** the documentation MUST explain `Прочитал`, `Взял`, `Research/Taken/`, `Research/Skipped/`, and how those signals affect future scoring

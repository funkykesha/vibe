## ADDED Requirements

### Requirement: Provider adapter boundary
The system SHALL isolate TBank-specific behavior behind a provider adapter contract.

#### Scenario: Provider accounts are fetched
- **WHEN** TBank account data is requested
- **THEN** provider-specific responses SHALL be normalized before sync logic uses them

### Requirement: Mapping state machine
The system SHALL track provider account mappings with explicit states.

#### Scenario: New provider account appears
- **WHEN** a provider account has no confirmed internal mapping
- **THEN** the system SHALL mark it unmapped or candidate and SHALL NOT update an internal balance

#### Scenario: User confirms mapping
- **WHEN** the user confirms a provider account maps to an internal account
- **THEN** the mapping MAY become confirmed if currency and type checks pass

### Requirement: Ambiguous and unsafe accounts
The system SHALL not silently write balances for ambiguous or unsafe provider data.

#### Scenario: Multiple possible matches exist
- **WHEN** a provider account could match multiple internal accounts
- **THEN** the system SHALL mark the mapping conflict or candidate and require user action

#### Scenario: Currency mismatch
- **WHEN** provider and internal account currencies differ
- **THEN** the system SHALL NOT update the internal balance without explicit correction

### Requirement: Stale mapping behavior
The system SHALL preserve internal accounts when provider accounts disappear.

#### Scenario: Confirmed provider account is missing
- **WHEN** a previously confirmed provider account is absent from a provider fetch
- **THEN** the mapping SHALL become stale
- **AND** the internal account SHALL NOT be deleted

### Requirement: Mocked adapter contract
The system SHALL verify sync behavior with a mocked provider adapter before live writes.

#### Scenario: Contract tests run
- **WHEN** sync behavior is tested with mocked provider accounts
- **THEN** confirmed mappings update only intended accounts and unsafe cases do not write

### Requirement: Live fetch gate
The system SHALL require a live local account fetch before enabling live sync writes.

#### Scenario: Live fetch has not passed
- **WHEN** sync is requested before live local account fetch validation
- **THEN** the system SHALL NOT apply provider balance writes

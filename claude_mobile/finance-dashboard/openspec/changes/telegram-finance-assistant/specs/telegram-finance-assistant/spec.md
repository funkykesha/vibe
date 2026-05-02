## ADDED Requirements

### Requirement: Authorization boundary
The Telegram assistant SHALL respond with financial data only to configured authorized user IDs.

#### Scenario: Unauthorized user sends command
- **WHEN** a non-authorized Telegram user sends a command
- **THEN** the bot SHALL NOT reveal financial data or perform writes

### Requirement: Local polling mode
The Telegram assistant SHALL support local polling as the first runtime mode.

#### Scenario: Bot starts locally
- **WHEN** required local bot configuration is present
- **THEN** the bot SHALL receive commands through polling

### Requirement: Summary command
The Telegram assistant SHALL provide `/summary` over shared finance state.

#### Scenario: Authorized user requests summary
- **WHEN** the authorized user sends `/summary`
- **THEN** the bot SHALL return current key totals, category context, and freshness information

### Requirement: Safe manual update command
The Telegram assistant SHALL support manual balance updates only after confirmation.

#### Scenario: Account match is clear
- **WHEN** the user sends an update command that matches one account
- **THEN** the bot SHALL show the matched account and requested balance before applying the write

#### Scenario: Account match is ambiguous
- **WHEN** the update command matches no accounts or multiple accounts
- **THEN** the bot SHALL ask for clarification and SHALL NOT write a balance

### Requirement: Snapshot command
The Telegram assistant SHALL provide `/snapshot` for explicit capital checkpoints when snapshot APIs are available.

#### Scenario: Snapshot API is available
- **WHEN** the authorized user sends `/snapshot`
- **THEN** the bot SHALL create a snapshot and return key totals plus label or timestamp

### Requirement: Shared-state visibility
Telegram writes SHALL be visible to the dashboard through shared backend state.

#### Scenario: Manual update is confirmed
- **WHEN** Telegram applies a confirmed manual account update
- **THEN** the updated balance SHALL be readable from the dashboard API

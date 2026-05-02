## ADDED Requirements

### Requirement: Telegram summary
The Telegram bot SHALL provide a concise mobile summary of the current financial position.

#### Scenario: Request summary
- **WHEN** the authorized user sends a summary command
- **THEN** the bot SHALL respond with current capital totals, category totals, and a timestamp or freshness indicator

### Requirement: Telegram automated refresh
The Telegram bot SHALL let the authorized user trigger supported account synchronization from mobile.

#### Scenario: Trigger refresh
- **WHEN** the authorized user sends a refresh command
- **THEN** the bot SHALL request automated account synchronization and report success, failure, and changed balances where available

### Requirement: Telegram manual update
The Telegram bot SHALL let the authorized user update non-automated account balances through short commands.

#### Scenario: Confirm matched account update
- **WHEN** the user sends a manual update command that matches an account
- **THEN** the bot SHALL show the matched account and requested new balance before applying the update

#### Scenario: Reject ambiguous account update
- **WHEN** the user sends a manual update command that matches multiple accounts or no accounts
- **THEN** the bot SHALL ask for clarification and SHALL NOT update balances silently

### Requirement: Telegram snapshot
The Telegram bot SHALL let the authorized user create an explicit capital snapshot after balance updates.

#### Scenario: Create mobile snapshot
- **WHEN** the authorized user sends a snapshot command
- **THEN** the bot SHALL create a snapshot from current balances and reply with key totals and the snapshot label or timestamp

### Requirement: Telegram guided future flows
The Telegram bot SHALL provide a path for guided interactive flows that cannot be done well as a single command.

#### Scenario: Start guided TBank auth
- **WHEN** the authorized user starts a TBank authorization flow
- **THEN** the bot SHALL collect the needed steps interactively and preserve account safety boundaries

#### Scenario: Receive future photo command
- **WHEN** the authorized user sends a photo before OCR is implemented
- **THEN** the bot SHALL acknowledge that photo processing is not yet available without modifying financial data

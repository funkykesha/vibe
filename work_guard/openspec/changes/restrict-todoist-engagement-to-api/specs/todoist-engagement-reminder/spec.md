## MODIFIED Requirements

### Requirement: Feature is opt-in and disabled by default
The Todoist engagement reminder SHALL be disabled by default and SHALL only activate when the user explicitly enables it in local configuration. Engagement detection SHALL require a Todoist API token; the token SHALL be read from local environment (`TODOIST_API_TOKEN`) and SHALL NOT be stored in `config.json`. When no token is available there SHALL be no engagement signal of any kind.

#### Scenario: Default configuration is inert
- **WHEN** WorkGuard runs with default configuration
- **THEN** no Todoist engagement monitoring occurs
- **THEN** no Todoist reminder overlay is shown
- **THEN** no outbound Todoist API call is made

#### Scenario: Enabled without token has no engagement signal
- **WHEN** the feature is enabled but `TODOIST_API_TOKEN` is not set
- **THEN** no outbound Todoist API call is made
- **THEN** no Todoist Interaction is tracked from any signal
- **THEN** the reminder may still be shown when work time and threshold gates are satisfied

#### Scenario: Token is not stored in config
- **WHEN** the user configures Todoist API access
- **THEN** the token is read from a local `.env` file or process environment
- **THEN** the token is not stored in `config.json`

### Requirement: Unavailable signals do not count as interaction
The system SHALL treat an unavailable or failed Todoist API signal as no observed Todoist Interaction. A failed signal SHALL NOT reset Todoist Non-Interaction Time and SHALL NOT suppress a reminder by itself.

#### Scenario: API source unavailable
- **WHEN** the Todoist API errors or is offline, or the token is invalid
- **THEN** the system logs the condition
- **THEN** the last engagement timestamp is not advanced by that failed signal
- **THEN** the reminder may still be shown when work time and threshold gates are satisfied
- **THEN** the dashboard falls back to the latest successful Todoist Task Snapshot when available

## REMOVED Requirements

### Requirement: Engagement is derived from three signal families
**Reason**: Engagement is redefined to mean acting on tasks, not viewing Todoist. The frontmost-app and Chromium browser-history signals are removed; engagement now derives only from the Todoist REST API. Replaced by the "Engagement is derived from the Todoist API" requirement.
**Migration**: No config migration required. The `history_browsers` and `frontmost_app_name` config keys become inert (ignored). Users relying on app-viewing or browser-tab viewing to reset the timer must instead complete, add, move, or delete a task; viewing Todoist no longer counts as interaction. A Todoist API token is now required for any engagement detection.

## ADDED Requirements

### Requirement: Engagement is derived from the Todoist API
The system SHALL compute the most recent Todoist engagement timestamp solely from user-visible task changes observed via the Todoist REST API (snapshot-diff active-task changes, completed tasks, and deleted/moved/reordered activity). The frontmost application name and browser history SHALL NOT be consulted as engagement signals. System Todoist Changes SHALL NOT count as Todoist Interaction.

#### Scenario: Viewing Todoist does not count as engagement
- **WHEN** the user opens or focuses the Todoist app or visits `todoist.com` in a browser without changing any task
- **THEN** the last engagement timestamp is not advanced
- **THEN** WorkGuard does not read the frontmost application name or any browser history for engagement

#### Scenario: User-visible API task mutation counts as interaction
- **WHEN** Todoist activity or completed-task data reports a task change in the recency lookback window
- **AND** the difference is not classified as System Todoist Change
- **THEN** the last engagement timestamp is set to the Todoist-provided change time when available

#### Scenario: Cold start active task recency counts as interaction
- **WHEN** the first successful API poll has no previous active-task snapshot
- **AND** an active task has `updated_at` within the configured threshold
- **AND** the task change is not classified as System Todoist Change
- **THEN** the last engagement timestamp is advanced to that `updated_at` time

#### Scenario: System recurring reschedule does not count
- **WHEN** an active recurring task changes only because Todoist automatically rescheduled its due date
- **THEN** the last engagement timestamp is not advanced by that change

#### Scenario: Activity data classifies system changes
- **WHEN** Todoist activity data includes update metadata such as `old_item` or `update_intent`
- **THEN** the system uses that metadata to classify System Todoist Changes before advancing the engagement timestamp

#### Scenario: Completed task counts as interaction
- **WHEN** the Todoist API reports a completed task in the recency lookback window
- **THEN** the last engagement timestamp is advanced to that task's `completed_at` time

#### Scenario: Deleted task counts as interaction
- **WHEN** the Todoist API reports a deleted task activity in the recency lookback window
- **THEN** the last engagement timestamp is advanced to that activity's event time

#### Scenario: Moved or reordered task counts as interaction
- **WHEN** Todoist activity reports an `item:moved` or `item:reordered` event in the recency lookback window
- **THEN** the last engagement timestamp is advanced to that activity's event time

#### Scenario: Completed and deleted recency lookback
- **WHEN** the system queries completed tasks or deleted task activity
- **THEN** the lookback window starts at `now - (idle_threshold_min + poll_interval_min + 5 minutes)`

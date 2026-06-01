# todoist-engagement-reminder Specification

## Purpose
Opt-in, default-disabled monitor that, during work time, tracks the user's most recent Todoist Interaction across three local signals (frontmost Todoist app, Chromium browser history visits to `todoist.com`, and Todoist REST API task changes) and shows a full-screen reminder overlay with a task mini-dashboard when Todoist Non-Interaction Time exceeds a configured threshold.

## Requirements
### Requirement: Feature is opt-in and disabled by default
The Todoist engagement reminder SHALL be disabled by default and SHALL only activate when the user explicitly enables it in local configuration. A Todoist API token SHALL NOT be required for app/browser monitoring; it SHALL be read from local environment (`TODOIST_API_TOKEN`) and SHALL only enable the API signal and API-backed dashboard data.

#### Scenario: Default configuration is inert
- **WHEN** WorkGuard runs with default configuration
- **THEN** no Todoist engagement monitoring occurs
- **THEN** no Todoist reminder overlay is shown
- **THEN** no outbound Todoist API call is made

#### Scenario: Enabled without token stays inert for API
- **WHEN** the feature is enabled but `TODOIST_API_TOKEN` is not set
- **THEN** no outbound Todoist API call is made
- **THEN** Todoist Interaction is still tracked from app and browser signals
- **THEN** the reminder may still be shown when work time and threshold gates are satisfied

#### Scenario: Token is not stored in config
- **WHEN** the user configures Todoist API access
- **THEN** the token is read from a local `.env` file or process environment
- **THEN** the token is not stored in `config.json`

### Requirement: Engagement is derived from three signal families
The system SHALL compute the most recent Todoist engagement timestamp as the maximum of: frontmost application equal to `Todoist`, the latest `todoist.com` visit time read from Chromium browser history (Yandex, Chrome), and Todoist-provided event/change times observed via the REST API for user-visible task changes. System Todoist Changes SHALL NOT count as Todoist Interaction.

#### Scenario: Frontmost Todoist counts as engagement
- **WHEN** the monitoring tick observes the frontmost application name is `Todoist`
- **THEN** the last engagement timestamp is set to the current time

#### Scenario: Background Todoist does not count as engagement
- **WHEN** Todoist is running but is not the frontmost application
- **THEN** the app signal does not advance the last engagement timestamp

#### Scenario: Browser visit counts as engagement
- **WHEN** the latest `todoist.com` visit in a configured Chromium history is newer than the stored engagement time
- **THEN** the last engagement timestamp is advanced to that visit time
- **THEN** the system does not need to prove that the browser tab was frontmost

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

### Requirement: Reminder fires only during work time after the non-interaction threshold
The system SHALL show the reminder only during work time. The system SHALL use the configured non-interaction threshold from the last Todoist Interaction time, including interactions that happened before WorkGuard could check them. The system SHALL NOT suppress the reminder merely because the user is inactive at the computer or active in another application.

#### Scenario: Non-interaction past threshold during work time
- **WHEN** it is work time and a current-period Todoist Interaction happened more than the configured threshold ago
- **THEN** the reminder overlay is shown

#### Scenario: Morning check with recent pre-open interaction
- **WHEN** WorkGuard performs the first available reminder check in a work period
- **AND** Todoist changed before the laptop was opened
- **AND** that Todoist Change Time is not older than the configured threshold
- **THEN** no reminder overlay is shown

#### Scenario: Morning check with stale or absent interaction
- **WHEN** WorkGuard performs the first available reminder check in a work period
- **AND** the latest Todoist Interaction is older than the configured threshold or absent
- **THEN** the reminder overlay is shown immediately

#### Scenario: Breaks do not pause non-interaction time
- **WHEN** the current time is inside the configured work window
- **THEN** lunches, breaks, and computer inactivity do not pause Todoist Non-Interaction Time

#### Scenario: Computer inactivity does not suppress reminder
- **WHEN** it is work time and the threshold is exceeded without Todoist Interaction
- **THEN** the reminder overlay MAY be shown even if the user is inactive at the computer

#### Scenario: Repeat cadence after dismissal
- **WHEN** the reminder was shown and Todoist Non-Interaction Time remains past threshold
- **THEN** the next reminder is not shown earlier than the configured repeat cadence

### Requirement: Reminder overlay presents a non-interactive task dashboard
The reminder overlay SHALL be full-screen without a countdown timer, SHALL present two actionable buttons, and SHALL display a non-clickable Todoist task summary sourced from the latest successful Todoist Task Snapshot refreshed periodically in the background.

#### Scenario: Overlay content
- **WHEN** the reminder overlay is shown
- **THEN** it lists priority p1 and p2 tasks expanded up to the configured cap with an overflow indicator when exceeded
- **THEN** it shows the counts of p3 and p4 tasks and the number of overdue tasks
- **THEN** the task summary is not interactive

#### Scenario: Overlay uses last successful task snapshot
- **WHEN** the reminder overlay is shown after at least one successful Todoist task poll
- **THEN** the dashboard is rendered from the latest successful Todoist Task Snapshot
- **THEN** the overlay does not perform a live Todoist API fetch at display time

#### Scenario: Overlay without task snapshot
- **WHEN** the reminder overlay is shown before any Todoist Task Snapshot exists
- **THEN** the overlay still shows the reminder message and actions
- **THEN** no task details are displayed

#### Scenario: Open Todoist action
- **WHEN** the user activates the "open Todoist" button
- **THEN** the system opens the local Todoist application and dismisses the overlay
- **THEN** the last engagement timestamp is advanced immediately, without waiting for the next monitoring tick
- **THEN** the next reminder is governed by the normal non-interaction threshold from that timestamp, not by the repeat cadence

#### Scenario: Dismiss action
- **WHEN** the user activates the "dismiss" button
- **THEN** the overlay closes and the repeat cadence is armed
- **THEN** the last engagement timestamp is not advanced

### Requirement: Unavailable signals do not count as interaction
The system SHALL treat an unavailable or failed Todoist signal as no observed Todoist Interaction. A failed signal SHALL NOT reset Todoist Non-Interaction Time and SHALL NOT suppress a reminder by itself.

#### Scenario: Signal sources unavailable
- **WHEN** browser history is unreadable, the API errors or is offline, or the token is invalid
- **THEN** the system logs the condition
- **THEN** the last engagement timestamp is not advanced by that failed signal
- **THEN** the reminder may still be shown when work time and threshold gates are satisfied
- **THEN** the dashboard falls back to the latest successful Todoist Task Snapshot when available

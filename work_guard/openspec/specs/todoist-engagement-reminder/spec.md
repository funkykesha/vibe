# todoist-engagement-reminder Specification

## Purpose
Opt-in, default-disabled monitor that, during work time, tracks the user's most recent Todoist Interaction via the Todoist REST API (user-visible task changes) and shows a full-screen reminder overlay with a task mini-dashboard when Todoist Non-Interaction Time exceeds a configured threshold.

## Requirements
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
The reminder overlay SHALL be full-screen without a countdown timer, SHALL present two actionable buttons, and SHALL display a non-clickable Todoist task dashboard sourced from the latest successful Todoist Task Snapshot refreshed periodically in the background. The dashboard SHALL include only tasks that have a due date, SHALL group tasks by priority, SHALL show a relative due label per task, and SHALL adapt its layout to the monitor's pixel width.

#### Scenario: Dated tasks only
- **WHEN** the reminder overlay is shown
- **THEN** only tasks that have a due date or due datetime no later than today are listed
- **THEN** tasks without any due date are not listed
- **THEN** the number of undated tasks excluded is available per priority for the section counter

#### Scenario: Priority-grouped sections across all four priorities
- **WHEN** the reminder overlay is shown
- **THEN** all four priorities (p1, p2, p3, p4) are represented
- **THEN** each priority is visually distinguished using the Todoist priority color (p1 red, p2 orange, p3 blue, p4 gray)
- **THEN** within a listed priority section tasks are ordered by due date ascending, with overdue tasks first
- **THEN** the task dashboard is not interactive

#### Scenario: Priority sections rendered as task cards
- **WHEN** a priority is shown as a full task list
- **THEN** the section is a bordered box with a header carrying a colored accent flag, the priority label in the accent color, and the section's dated task count
- **THEN** each task is a card showing a priority dot, the task content, an optional project label, and the relative due label
- **THEN** the actions row presents the two buttons centered

#### Scenario: Per-task relative due label with red overdue
- **WHEN** a task is listed in the dashboard
- **THEN** the task row shows a relative due label (for example "просрочено 3д", "сегодня", "завтра", "Пн 12", "23 июн")
- **THEN** when the task is overdue its due label is rendered in red
- **THEN** when the task is not overdue its due label is rendered in a neutral color

#### Scenario: Per-section counters
- **WHEN** a priority section is shown as a task list
- **THEN** the section header reports its dated task count
- **THEN** the section's stat footer reports the overdue count and the undated-hidden count for that priority

#### Scenario: Dynamic per-section task cap
- **WHEN** a priority section cannot fit all its dated tasks in the available section height
- **THEN** the section lists as many tasks as fit at the fixed row pitch
- **THEN** the section shows an overflow indicator "…ещё N" for the remaining tasks

#### Scenario: Two-tier width-responsive layout
- **WHEN** the monitor pixel width is below the wide-tier threshold
- **THEN** the dashboard uses two columns
- **THEN** the p1 task list fills the left column and the p2 task list occupies the top of the right column
- **THEN** p3 and p4 are presented as compact count-cards (not task-by-task lists) below the p2 list
- **WHEN** the monitor pixel width is at or above the wide-tier threshold
- **THEN** the dashboard uses four columns, one priority per column, with all four priorities shown as full task lists

#### Scenario: Low-priority count-cards in the narrow tier
- **WHEN** the dashboard is shown below the wide-tier threshold
- **THEN** each of p3 and p4 is shown as a single count-card reporting its dated task count
- **THEN** the count-card also reports that priority's overdue and undated-hidden counts
- **THEN** no individual p3 or p4 task rows are listed in this tier

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
The system SHALL treat an unavailable or failed Todoist API signal as no observed Todoist Interaction. A failed signal SHALL NOT reset Todoist Non-Interaction Time and SHALL NOT suppress a reminder by itself.

#### Scenario: API source unavailable
- **WHEN** the Todoist API errors or is offline, or the token is invalid
- **THEN** the system logs the condition
- **THEN** the last engagement timestamp is not advanced by that failed signal
- **THEN** the reminder may still be shown when work time and threshold gates are satisfied
- **THEN** the dashboard falls back to the latest successful Todoist Task Snapshot when available

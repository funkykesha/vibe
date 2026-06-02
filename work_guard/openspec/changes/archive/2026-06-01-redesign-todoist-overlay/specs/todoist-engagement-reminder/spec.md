## MODIFIED Requirements

### Requirement: Reminder overlay presents a non-interactive task dashboard
The reminder overlay SHALL be full-screen without a countdown timer, SHALL present two actionable buttons, and SHALL display a non-clickable Todoist task dashboard sourced from the latest successful Todoist Task Snapshot refreshed periodically in the background. The dashboard SHALL include only tasks that have a due date, SHALL group tasks by priority, SHALL show a relative due label per task, and SHALL adapt its layout to the monitor's pixel width.

#### Scenario: Dated tasks only
- **WHEN** the reminder overlay is shown
- **THEN** only tasks that have a due date or due datetime are listed
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

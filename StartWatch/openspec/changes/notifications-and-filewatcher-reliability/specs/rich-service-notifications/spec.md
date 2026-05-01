## ADDED Requirements

### Requirement: Failure notification includes reason
When one or more services fail, the system SHALL send a macOS notification that includes the failure reason from the `detail` field when `showFailureDetails` is enabled.

#### Scenario: Single service failure with details enabled
- **WHEN** a service transitions from running to not-running and `notifications.showFailureDetails` is `true`
- **THEN** a notification is sent with title "Service Down: <name>" and body containing the `detail` string

#### Scenario: Single service failure with details disabled
- **WHEN** a service transitions from running to not-running and `showFailureDetails` is `false` or absent
- **THEN** a notification is sent with title "Service Down: <name>" and body "Not running"

#### Scenario: Multiple services fail simultaneously
- **WHEN** two or more services transition to not-running in the same check cycle
- **THEN** a single notification is sent with title "Services Down (N)" and body listing each service name and its detail separated by semicolons (when `showFailureDetails` is true)

#### Scenario: Subsequent failure notification replaces previous
- **WHEN** a failure notification was already shown and another service fails in the next cycle
- **THEN** the new notification replaces the previous one (same notification identifier reused)

### Requirement: Recovery notification sent on service restore
When a service transitions from not-running to running, the system SHALL send a recovery notification.

#### Scenario: Single service recovers
- **WHEN** a service that was previously not-running becomes running
- **THEN** a notification is sent with title "Service Recovered" and body containing the service name

#### Scenario: Recovery notification sent regardless of onlyOnFailure flag
- **WHEN** `notifications.onlyOnFailure` is `true` and a service recovers
- **THEN** a recovery notification is still sent

#### Scenario: Multiple services recover simultaneously
- **WHEN** two or more services transition to running in the same check cycle
- **THEN** a single notification is sent with title "Services Recovered" and body listing all service names

### Requirement: Config validation error notification
When a saved config file fails validation, the system SHALL send a notification with the validation errors.

#### Scenario: Invalid config saved
- **WHEN** the user saves a config file that fails validation (e.g., empty service name)
- **THEN** a notification is sent with title "Config Error" and body containing the validation error messages

#### Scenario: Config error notification uses stable identifier
- **WHEN** multiple invalid saves occur in sequence
- **THEN** each new config error notification replaces the previous one

### Requirement: No notifications on daemon startup
The system SHALL NOT send failure notifications based on the state observed at first check after daemon start.

#### Scenario: Service already down when daemon starts
- **WHEN** the daemon starts and the first check finds a service not running
- **THEN** no notification is sent; the state is recorded as baseline

#### Scenario: Service fails after startup baseline
- **WHEN** a service was running at first check and subsequently fails
- **THEN** a failure notification is sent

### Requirement: Starting services excluded from failure notifications
Services in the `isStarting` state SHALL NOT trigger failure notifications.

#### Scenario: Service in startup phase
- **WHEN** a service has `isRunning: false` and `isStarting: true`
- **THEN** no failure notification is sent for that service

#### Scenario: Service fails after startup timeout
- **WHEN** a service transitions from `isStarting: true` to `isRunning: false, isStarting: false`
- **THEN** no failure notification is sent (service was never observed as running)

### Requirement: Sound flag respected
All notification types SHALL respect the `notifications.sound` configuration flag.

#### Scenario: Sound enabled
- **WHEN** `notifications.sound` is `true`
- **THEN** notifications play the default system sound

#### Scenario: Sound disabled
- **WHEN** `notifications.sound` is `false` or absent
- **THEN** notifications are silent

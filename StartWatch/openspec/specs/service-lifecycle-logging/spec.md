## ADDED Requirements

### Requirement: Log service startup attempt
System SHALL log when service start operation is initiated.

#### Scenario: Service start command issued
- **WHEN** user or daemon triggers start command for a service
- **THEN** system logs: timestamp, "SERVICE_START_ATTEMPT", service name, command being executed

#### Scenario: Start command fails immediately
- **WHEN** service start command execution fails (e.g., command not found, permission denied)
- **THEN** system logs: timestamp, "SERVICE_START_ERROR", service name, error message

### Requirement: Log service readiness check
System SHALL log results of readiness checks after service startup.

#### Scenario: Service readiness check passes
- **WHEN** ServiceChecker performs check (process, port, HTTP, command) after start and finds service running/healthy
- **THEN** system logs: timestamp, "SERVICE_READY", service name, check type, result detail (e.g., port listening, HTTP 200)

#### Scenario: Service readiness check fails
- **WHEN** ServiceChecker performs check and finds service not running or unhealthy
- **THEN** system logs: timestamp, "SERVICE_NOT_READY", service name, check type, failure reason (e.g., port not listening, timeout)

### Requirement: Log service restart operation
System SHALL log when service restart is triggered and its outcome.

#### Scenario: Service restart initiated
- **WHEN** restart command is executed for a running service
- **THEN** system logs: timestamp, "SERVICE_RESTART_ATTEMPT", service name, restart strategy (stop then start)

#### Scenario: Service restart completes successfully
- **WHEN** restart sequence completes and service is confirmed running
- **THEN** system logs: timestamp, "SERVICE_RESTART_SUCCESS", service name

#### Scenario: Service restart fails
- **WHEN** restart sequence fails (service doesn't stop or doesn't start after stopping)
- **THEN** system logs: timestamp, "SERVICE_RESTART_ERROR", service name, failure stage (stop/start), error message

### Requirement: Log service state transitions
System SHALL log significant state changes in service lifecycle.

#### Scenario: Service transitions to running state
- **WHEN** service transitions from not-running to running (detected by check)
- **THEN** system logs: timestamp, "SERVICE_UP", service name, time since last check detected change

#### Scenario: Service transitions to stopped state
- **WHEN** service transitions from running to not-running (detected by check)
- **THEN** system logs: timestamp, "SERVICE_DOWN", service name, last known status

### Requirement: Log daemon startup sequence
System SHALL log daemon initialization and service monitoring startup.

#### Scenario: Daemon starts and loads config
- **WHEN** StartWatch daemon process starts
- **THEN** system logs: timestamp, "DAEMON_START", daemon version, pid, working directory

#### Scenario: Daemon begins monitoring services
- **WHEN** all services are loaded and monitoring loop starts
- **THEN** system logs: timestamp, "MONITORING_START", count of services being monitored

#### Scenario: Daemon shutdown
- **WHEN** daemon process terminates
- **THEN** system logs: timestamp, "DAEMON_STOP", uptime, reason (signal, user request, error)

### Requirement: Structured log format for service logs
All service lifecycle logs SHALL follow format: `{timestamp, level, component, event, details}` as JSON line.

#### Scenario: Example service log entry
- **WHEN** service event occurs
- **THEN** log entry format: `{"timestamp":"2026-04-30T10:15:23Z","level":"INFO","component":"ServiceRunner","event":"SERVICE_READY","details":{"serviceName":"redis","checkType":"port","checkResult":true}}`

## 1. Logger Infrastructure

- [x] 1.1 Create Logger utility module in Core (JSON lines format, async dispatch)
- [x] 1.2 Implement log file management (path: ~/.config/startwatch/logs/events.json)
- [x] 1.3 Add structured log entry type (timestamp, level, component, event, details)
- [x] 1.4 Implement async-safe append to events.json using DispatchQueue

## 2. Config Logging

- [x] 2.1 Add CONFIG_LOAD_START log in ConfigManager.load() when file access begins
- [x] 2.2 Add CONFIG_LOAD_ERROR log when config file not found or unreadable
- [x] 2.3 Add CONFIG_PARSE_SUCCESS log after successful JSON decoding with service count
- [x] 2.4 Add CONFIG_PARSE_ERROR log with decoder error details on parse failure
- [x] 2.5 Add CONFIG_VALIDATE_SUCCESS log after schema validation passes
- [x] 2.6 Add CONFIG_VALIDATE_ERROR log with failure details if validation fails
- [x] 2.7 Add CONFIG_APPLY_SUCCESS log when loaded config applied to runtime state
- [x] 2.8 Add CONFIG_CHANGE_DETECTED log when reloaded config differs from previous

## 3. Service Lifecycle Logging

- [x] 3.1 Add SERVICE_START_ATTEMPT log in ServiceRunner.start() with command
- [x] 3.2 Add SERVICE_START_ERROR log if start command fails
- [x] 3.3 Add SERVICE_READY log in ServiceChecker when check passes (process/port/http/command)
- [x] 3.4 Add SERVICE_NOT_READY log with check type and failure reason
- [x] 3.5 Add SERVICE_RESTART_ATTEMPT log at start of restart sequence
- [x] 3.6 Add SERVICE_RESTART_SUCCESS log after successful restart completion
- [x] 3.7 Add SERVICE_RESTART_ERROR log with failure stage (stop/start) and error
- [x] 3.8 Add SERVICE_UP log on state transition from not-running to running (logged via SERVICE_READY on state change)
- [x] 3.9 Add SERVICE_DOWN log on state transition from running to not-running (logged via SERVICE_NOT_READY on state change)
- [x] 3.10 Add DAEMON_START log on daemon initialization with version, pid, working dir
- [x] 3.11 Add MONITORING_START log when all services loaded and monitoring begins
- [ ] 3.12 Add DAEMON_STOP log on daemon shutdown with uptime and reason

## 4. CLI Integration

- [x] 4.1 Add `startwatch logs` CLI command skeleton
- [x] 4.2 Implement log file reading and JSON line parsing
- [x] 4.3 Add filtering by --service flag
- [x] 4.4 Add filtering by --since ISO8601 timestamp flag
- [x] 4.5 Add filtering by --level flag (INFO, ERROR)
- [x] 4.6 Implement human-readable output formatting (timestamp, service, event, details)
- [ ] 4.7 Test logs command with various filter combinations

## 5. Testing & Verification

- [ ] 5.1 Add unit tests for Logger module (write, read, format)
- [ ] 5.2 Add integration test: config load with logging verification
- [ ] 5.3 Add integration test: service start with logging verification
- [ ] 5.4 Add integration test: logs CLI command with filtering
- [ ] 5.5 Manual test: Start daemon, verify events.json created with correct entries
- [ ] 5.6 Manual test: Run logs CLI command, verify output accuracy

## Why

StartWatch manages services and applies configurations at runtime. Currently no visibility into:
- When config is loaded, parsed, or applied
- When services start, stop, or encounter errors during startup

This makes debugging configuration issues and service lifecycle problems difficult. Need structured logging across config system and daemon startup.

## What Changes

- Add logging to config parsing and application flow
- Add logging to service startup and lifecycle events
- Make log output available via CLI and structured for analysis

## Capabilities

### New Capabilities
- `config-logging`: Log config access, parsing, validation, and application (when app reads config, how it changes behavior)
- `service-lifecycle-logging`: Log service startup sequence, readiness checks, and shutdown events

### Modified Capabilities
<!-- No existing spec behavior changes -->

## Impact

- Core/Config modules: add logging around config loading/application
- Daemon/ServiceManager: add startup/lifecycle event logging
- CLI output: expose logs in CLI commands (status, logs)
- Log format: structured (timestamp, level, service name, event type)

## Why

Config changes require daemon restart to take effect. Users expect to edit `~/.config/startwatch/config.json` and have changes apply immediately without manual restart. Additionally, invalid config (missing fields, typos) silently fails instead of alerting the user, leading to services disappearing from monitoring.

## What Changes

- Daemon monitors config file for changes and reloads automatically (hotreload)
- Config is validated on load; validation errors logged with clear messages
- Daemon logs when config is reloaded, what changed, and any validation errors
- Invalid config is rejected; previous valid config remains in effect until fixed

## Capabilities

### New Capabilities
- `config-file-watching`: Monitor config file for changes and reload without daemon restart
- `config-validation-with-logging`: Validate config on load and log errors with actionable messages

### Modified Capabilities
<!-- None —these are new features, not spec changes -->

## Impact

- **Affected files**: `Sources/StartWatch/Daemon/AppDelegate.swift` (DaemonCoordinator), `Sources/StartWatch/Core/Config.swift` (ConfigManager, validation)
- **New dependencies**: FileWatcher or FSEvents API (macOS native, no external dependencies)
- **User experience**: Config changes apply immediately; errors are visible in logs
- **No breaking changes**: Existing config format unchanged; backward compatible

## Why

Currently, when `npm start` launches eliza-proxy, there's no visibility into which Eliza models are available and whether they're accessible. Users don't know if the service is healthy until they try to make a request. Adding startup diagnostics reveals model availability in real-time, making troubleshooting and monitoring easier.

## What Changes

- Add real-time model status display during startup
- Show each provider's models grouped with status (✅ available, ❌ failed, ⏳ checking)
- Display progress bar per provider showing probed / total models
- Format is compact (progress bar + inline model list, wraps to 2-3 lines per provider)
- Groups appear in order of readiness, not all at once
- Output updates incrementally without clearing screen

## Capabilities

### New Capabilities
- `model-startup-logging`: Real-time display of model availability during server startup, grouped by provider with progress tracking

### Modified Capabilities
- (none — this is a logging feature, no API or requirement changes)

## Impact

- **Code affected**: `server.js` (startup initialization), `lib/eliza-client/index.js` (probe callbacks), new module `lib/format-startup.js`
- **No breaking changes**: Pure logging enhancement, zero impact on `/v1/chat`, `/v1/models`, or other APIs
- **Dependencies**: No new dependencies, uses ANSI color codes for terminal output
- **User impact**: Better visibility into service health without code changes

## Why

Server currently stays running in terminal after completing model probe, requiring manual Ctrl+C to exit. Auto-exit after probe completes provides a cleaner user experience for quick validation scripts or CI/CD scenarios where you just want to check model availability.

## What Changes

- Add command-line flag `--exit-after-probe` to trigger auto-exit after all models are probed
- Server waits for all probe requests to complete, logs final results, then exits with code 0
- Exit codes: 0 for successful startup (all models probed), 1 for startup errors
- **BREAKING**: None - this is opt-in via command-line flag

## Capabilities

### New Capabilities
- `auto-exit-after-probe`: Server can automatically exit after model probe completes when started with `--exit-after-probe` flag

### Modified Capabilities
- None

## Impact

**Affected Code:**
- `server.js` - Add `--exit-after-probe` flag handling and exit logic
- `lib/eliza-client/index.js` - Add callback or Promise for probe completion detection

**Affected APIs:**
- CLI interface only - HTTP API behavior unchanged
- New command-line option: `npm start -- --exit-after-probe`

**Behavioral Changes:**
- With flag: Server exits after probe completes
- Without flag: Server keeps running (current behavior)

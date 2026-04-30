## Why

The auto-exit-after-probe feature has a race condition where model probes may complete before `totalModels` is initialized from the async model fetch callback. This causes the exit condition check to fail, preventing the server from exiting even when all probes have completed.

## What Changes

- Add `modelsLoaded` flag to track when `totalModels` has been initialized
- Update exit condition in `onModelUpdate` callback to check `modelsLoaded` flag
- Set `modelsLoaded = true` when `totalModels` is calculated in the async fetch callback
- This ensures the server only exits after all probes complete AND `totalModels` is set

No breaking changes - this is a bug fix for the existing auto-exit feature.

## Capabilities

### Modified Capabilities
- `auto-exit-after-probe`: Add race condition handling to ensure reliable exit behavior

## Impact

- Modified code: `server.js` (lines 30-75)
- No API changes - internal behavior fix only
- No new dependencies
- Tests should verify exit behavior under race conditions

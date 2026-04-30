## Why

Model probing at startup currently uses 4-second timeout per request (58 models × 4s = 3+ minutes). Reducing timeout to 1-2 seconds (fast fail) eliminates waiting for slow/unresponsive endpoints, cutting probe time to ~1-2 minutes total.

## What Changes

- Reduce `REQUEST_TIMEOUT_MS` in `lib/eliza-client/probe.js` from 4000ms to 1000ms (or 2000ms as fallback)
- Models that respond within 1s are verified immediately
- Models that timeout after 1s are marked unavailable
- Faster probe completion = faster server startup display

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- `lib/eliza-client/probe.js`: Lower timeout constant
- Server startup time: reduced from ~3 min to ~1-2 min (sequential) or ~30-40s (if using concurrency)
- Trade-off: some slow-but-working endpoints may be marked unavailable (acceptable for availability check)

## Context

Current probe uses 4-second timeout per model. Sequential probing (58 models × 4s = 3+ min) means users wait a long time for initial display.

## Goals / Non-Goals

**Goals:**
- Reduce probe timeout from 4s to 1-2s per request
- Cut total probe time in half (1-2 min for sequential, 15-30s for parallel)
- Preserve per-model callback structure (real-time UI updates)

**Non-Goals:**
- Change probing strategy (sequential vs parallel)
- Retry logic or fallback mechanisms
- Endpoint response quality analysis

## Decisions

**Decision: Set timeout to 1000ms (1 second)**

- Fast endpoints respond in <100ms
- Slow but functional endpoints typically timeout after 1-2s
- 1s cutoff: fast fail without losing legitimate endpoints
- Alternative: 2000ms for more tolerance (slightly slower but safer)
- Rationale: 1s is aggressive but appropriate for availability check (not latency measurement)

## Risks / Trade-offs

**Risk: Slow endpoints marked unavailable** → Acceptable. Probe checks *availability*, not latency. 4-second-response endpoints are too slow for real use anyway.

**Risk: Network variance causes false failures** → Mitigated by checking again on next server restart. Users can retry.

**Trade-off: Speed vs reliability** → Prioritize speed (per user request). Slow endpoints are filtered out, fast ones work immediately.

## Migration Plan

1. Change `REQUEST_TIMEOUT_MS` in `lib/eliza-client/probe.js`
2. Test with `npm start` to verify faster completion
3. No API changes or fallback needed
4. Backward compatible (just affects probe duration)

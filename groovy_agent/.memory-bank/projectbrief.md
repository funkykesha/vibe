# Project Brief

## What

Browser-based AI agent for writing and executing Groovy scripts for JSON transformation, powered by Yandex Eliza API (proxy to OpenAI, Anthropic, and other LLM providers).

**Stack:** Node.js 18+ (Express) + single-page HTML/CSS/JS frontend. No build step.

## Current initiative

Extract duplicated Eliza API code from `server.js` (~911 lines) and `scripts/test-models.js` (~782 lines) into a reusable local module `lib/eliza-client/`.

**Goals:**
1. Eliminate ~400 lines of duplication
2. Fix cold-start perf: UI blocked 3-5 min → unblocked immediately (two-tier model loading)
3. Module reusable in other projects via `file:../groovy_agent/lib/eliza-client`

## Key design decisions

- Closure factory (`createElizaClient`) not class — avoids `this` binding issues
- Two-tier model loading: raw list returned instantly (~200ms), probe runs in background (CONCURRENCY=15, timeout=4s, ~30-60s total)
- `fetchPromise` singleton — prevents double GET /v1/models on concurrent cold-start
- `probePromise` singleton — prevents double probe, 30s cooldown after failure
- `startProbeIfNeeded()` called on every `getModels()` — enables retry after failures
- `onValidated(cb)` called immediately if `validatedCache` exists

## Auth

`Authorization: OAuth <ELIZA_TOKEN>` (not Bearer).

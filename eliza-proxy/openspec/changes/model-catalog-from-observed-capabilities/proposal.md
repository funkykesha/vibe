## Why

The current startup probe spends real model tokens to validate the catalog, yet it does not prove that a model works through this proxy's streaming chat path. This causes unsupported models such as `gpt-5.4-pro` to remain visible until chat fails, while preview models observed in production, such as Gemini 3 variants, can be filtered out by static name rules.

## What Changes

- **BREAKING**: Startup model probing is no longer enabled by default.
- Model visibility is decided by deterministic catalog rules: provider family, chat capability, streaming capability, non-chat exclusion, and optional preview policy.
- Monium production metrics become an observed-health input for model freshness and stream support, using fixed selectors and absolute time windows.
- `/v1/models` hides models that this proxy cannot serve through `/v1/chat` streaming.
- Probe remains available as an explicit diagnostic path, not as the default catalog source of truth.
- Probe results no longer override catalog visibility; they only annotate diagnostics when explicitly requested.

## Capabilities

### New Capabilities
- `observed-model-catalog`: Builds a deterministic model catalog from Eliza catalog data, local capability rules, and Monium observed metrics.

### Modified Capabilities
- `model-startup-logging`: Startup no longer runs paid background probes by default, and startup display reflects catalog readiness plus optional observed health.
- `model-status-dashboard`: Dashboard no longer assumes probe lifecycle is the primary model status source; it reports catalog health and optional diagnostic probe data.

## Impact

- Affected code: `lib/eliza-client/models.js`, `lib/eliza-client/routing.js`, `lib/eliza-client/probe.js`, `lib/eliza-client/index.js`, `server.js`, `lib/probe-state.js`, dashboard rendering, and related tests.
- Affected APIs: `/v1/models`, `/v1/probe-status`, `/v1/health`, `/v1/probe`, and `/v1/chat` error behavior for unsupported models.
- External system: Monium MCP/metrics for project `eliza`, dashboard `monn56eeuq4tcmj8hd81`, sensor `chat.status`.
- Operational effect: default startup avoids real model calls and token spend; explicit probe mode still performs real calls.

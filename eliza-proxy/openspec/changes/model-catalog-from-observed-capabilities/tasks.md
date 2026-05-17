## 1. Capability Catalog

- [x] 1.1 Add tests showing non-streaming GPT models such as `gpt-5.4-pro` are excluded from the selectable model catalog.
- [x] 1.2 Add tests showing compatible streaming chat models remain included with provider, family, stability, and capability metadata.
- [x] 1.3 Add capability metadata helpers that classify chat, streaming, non-chat, stable, and preview models.
- [x] 1.4 Update model parsing so selectable output is filtered by proxy serving capabilities rather than probe result.
- [x] 1.5 Update routing tests for current GPT, Gemini, Claude, and internal model examples used by the catalog rules.

## 2. Opt-In Probe Flow

- [x] 2.1 Add tests proving `getModels()` does not call `runProbe()` by default.
- [x] 2.2 Add explicit probe mode wiring through options and environment or CLI configuration.
- [x] 2.3 Keep `POST /v1/probe` functional as a manual diagnostic operation.
- [x] 2.4 Ensure probe warning/error metadata annotates diagnostics without removing compatible models from `/v1/models`.
- [x] 2.5 Update startup behavior so default startup does not spend model tokens.

## 3. Monium Observed Facts

- [x] 3.1 Add fixture-based tests for parsing Monium `read_metrics` text responses into model facts.
- [x] 3.2 Implement deterministic observed-facts parsing for labels `model`, `vendor`, `provider`, `stream`, and aggregate values.
- [x] 3.3 Implement bounded Monium query planning by fixed UTC window and vendor/status/stream chunks.
- [x] 3.4 Merge observed facts into catalog models with `observedStatus200`, `observedStreamTrue`, and observation window metadata.
- [x] 3.5 Report observed models missing from the Eliza catalog as diagnostics without exposing them as selectable models.

## 4. API And Dashboard Semantics

- [x] 4.1 Update `/v1/models` tests for compatibility metadata, observed metadata, preview metadata, and hidden unsupported models.
- [x] 4.2 Update `/v1/probe-status` to report catalog readiness when no explicit probe is running.
- [x] 4.3 Update `/v1/health` to include catalog readiness and optional probe lifecycle.
- [x] 4.4 Update dashboard rendering to separate catalog availability from optional diagnostic probe status.
- [x] 4.5 Update startup display tests for default catalog readiness and explicit probe mode.

## 5. Documentation And Verification

- [x] 5.1 Update docs to explain that startup probe is opt-in and can spend real model tokens.
- [x] 5.2 Document deterministic Monium query requirements: absolute window, fixed selectors, chunking, and zero-traffic filtering.
- [x] 5.3 Run the full Node test suite.
- [x] 5.4 Manually verify `/v1/models`, `/v1/health`, and `/v1/probe-status` response shapes with probe disabled.
- [x] 5.5 Manually verify explicit probe mode still produces diagnostic probe metadata.

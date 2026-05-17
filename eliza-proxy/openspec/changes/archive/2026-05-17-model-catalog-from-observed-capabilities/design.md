## Context

The proxy currently treats model probing as part of catalog validation. `getModels()` fetches the Eliza catalog, starts background probes, and later replaces the raw catalog with probed metadata. Each probe sends a real short completion request, which spends model tokens and validates a `stream:false` request shape rather than the `/v1/chat` SSE contract used by this proxy.

This creates two catalog failures:
- Models that cannot stream through this proxy can still be listed until `/v1/chat` fails with `Model ... does not support streaming`.
- Models observed in production, such as Gemini preview variants, can be removed by local static filters before the user can select them.

Monium already records production request outcomes through `chat.status` metrics. Those metrics cannot prove future availability, but they can deterministically describe which models were recently observed, with which vendor and stream mode, for a fixed time window.

## Goals / Non-Goals

**Goals:**
- Make `/v1/models` deterministic and aligned with `/v1/chat` support.
- Stop default startup token spend from model probes.
- Keep an explicit probe path for manual diagnostics.
- Use Monium observed metrics as freshness and stream-support evidence without making `now`-based behavior implicit.
- Preserve existing dashboard/status surfaces while shifting their meaning from probe-first to catalog-first.

**Non-Goals:**
- Build a full Monium UI or replace the Monium dashboard.
- Guarantee that a model will answer future requests solely because it was observed in metrics.
- Add non-streaming chat fallback in this change.
- Probe every model on every startup.
- Treat preview models as stable; they remain visibly marked as preview when included.

## Decisions

1. Catalog visibility is decided by capability rules before probe metadata.

   The catalog pipeline should parse raw Eliza models, infer provider/family, exclude non-chat models, compute local serving capabilities, and only expose models whose capabilities match the proxy's `/v1/chat` path. A model with `supportsStreaming: false` is hidden from `/v1/models` unless a future non-streaming endpoint is added.

   Alternative considered: keep all catalog models and return clearer chat errors. Rejected because the user-facing picker would still advertise models that cannot work.

2. Startup probe is opt-in.

   The default startup path should fetch and filter catalog data without sending model completions. Real probe calls remain available through explicit controls such as `POST /v1/probe`, a CLI flag, or an environment variable.

   Alternative considered: keep startup probe but lower concurrency or token count. Rejected because even cheap probes still validate the wrong contract and still spend real provider quota.

3. Monium observed models are an input, not the sole source of truth.

   A deterministic Monium reader should use absolute `from`/`to`, fixed selectors, and vendor/status chunks to avoid oversized responses. It should extract `model`, `vendor`, `provider`, `stream`, and aggregate values, then expose facts like `observedStatus200`, `observedStreamTrue`, `lastObservedWindow`, and `requestScore`.

   Alternative considered: call the dashboard with `now-1d` and parse visible widgets. Rejected because relative time and widget formatting make results non-repeatable.

4. Preview inclusion is policy-driven.

   Preview/experimental models may be included when observed with successful production traffic and compatible stream mode. They must carry stability metadata so UI and users can distinguish them from stable models.

   Alternative considered: keep filtering all preview models. Rejected because current production evidence shows Gemini 3 variants are actively present and useful.

5. Probe metadata is diagnostic annotation.

   Probe results can be attached to model or status responses when explicitly run, but they must not be required for catalog readiness and must not remove otherwise compatible models unless the user is viewing diagnostic results.

## Risks / Trade-offs

- Monium metrics can lag or miss low-traffic models -> Mitigation: combine Monium with the Eliza catalog and local capability rules, and make the observation window visible in API metadata.
- Fixed time windows can become stale -> Mitigation: expose the window and allow refresh jobs or explicit regeneration with a new absolute window.
- Hiding non-streaming models reduces visible choice -> Mitigation: this matches the current `/v1/chat` contract; future non-streaming support can reintroduce them under a separate capability.
- Preview models may be unstable -> Mitigation: mark `stability: preview` and keep the inclusion rule explicit.
- Monium MCP responses can exceed size limits -> Mitigation: chunk by vendor/status/stream and parse only labels and aggregates needed for catalog facts.

## Migration Plan

1. Add local capability metadata for each parsed model and route configuration.
2. Change default `getModels()` flow so it does not call `runProbe()` unless opt-in probe mode is enabled.
3. Add a deterministic Monium observed-model reader or injectable provider with tests that use fixture responses.
4. Merge catalog models with observed facts and expose compatibility/stability metadata from `/v1/models`.
5. Update dashboard/status endpoints to show catalog readiness and optional diagnostic probe state.
6. Keep rollback simple: re-enable startup probe through the explicit opt-in flag/env while retaining capability filters.

## Open Questions

- Should Monium reads happen on demand at server startup, from a checked-in/generated snapshot, or through a separate scheduled refresh?
- What exact default observation window should production use once implementation starts?
- Should preview models be included by default when observed, or behind an `INCLUDE_PREVIEW_MODELS=true` switch?

## Context

`eliza-proxy` currently fetches the model catalog, starts asynchronous probes, and renders terminal status updates as probe events arrive. The display treats probe failures as unavailable models, even though `/v1/chat` may still work later because probe uses a short startup request, different timing, and sometimes different failure modes such as timeout or quota.

Live measurement of the current catalog found 58 models with wide latency spread: internal models often answer within 100-300 ms, many OpenAI/Gemini models need 700-1400 ms, and Claude/Grok can need up to about 1800 ms. The existing `CONCURRENCY = 15` constant is not used by `runProbe()`, which currently probes sequentially, while high real concurrency can trigger Eliza inflight limits.

## Goals / Non-Goals

**Goals:**
- Keep server startup responsive while probes run in the background.
- Make model catalog presence separate from probe health.
- Show probe state in terminal and on the root browser page.
- Prevent terminal output from shifting, wrapping incorrectly, or merging lines.
- Preserve `--exit-after-probe` semantics with background bounded probes.

**Non-Goals:**
- Build a chat UI on the root page.
- Hide models from `/v1/models` because probe health is warning/error.
- Change `/v1/chat` SSE wire format.
- Solve provider endpoint routing issues beyond surfacing probe failure details.

## Decisions

- Use one in-memory probe state store shared by terminal rendering and HTTP status endpoints. Alternative: keep terminal-only state and recompute HTTP state from model cache. Shared state avoids drift between CLI and browser views.
- Keep server `listen()` independent from probe completion. Alternative: block startup until probes complete. Non-blocking startup lets `/v1/chat` work immediately and still leaves live probe visibility in terminal and browser.
- Use bounded probe concurrency with default `4`. Alternative: preserve sequential probing or use the old intended value `15`. Sequential probing is too slow with per-model timeouts, while high concurrency risks Eliza inflight quota errors.
- Use timeout policy with default `800 ms` plus model/provider overrides from measured latency. Alternative: a single global `5000 ms` timeout. A global long timeout makes startup status slow and hides which models are naturally fast or slow.
- Map probe outcomes to `success`, `warning`, and `error`. Alternative: binary success/error. Warning prevents temporary timeout, quota, empty response, or retryable request-shape failures from being displayed as inactive models.
- Render terminal output from a stable seeded model list. Alternative: add models as events arrive. Seeded output prevents visual movement and makes pending models visible immediately.
- Serve root dashboard as simple Express HTML/CSS/JS. Alternative: introduce React/Vite. A framework would be unnecessary for a read-only status page and would add build/runtime surface.

## Risks / Trade-offs

- Measured timeouts may age as model latency changes -> keep defaults configurable via environment and keep warning non-blocking.
- Probe warnings may look less decisive than red failures -> include `kind`, latency, and summary counts so users can distinguish timeout, quota, and hard failures.
- Browser polling adds request traffic -> poll frequently only while probe is running and slow down after completion.
- Terminal cursor control can corrupt logs -> use cursor rewriting only for TTY output and plain snapshots for non-TTY logs.
- Background probes can complete before model display seed -> buffer early events and apply them after seeding.

## Migration Plan

Implement behind existing startup path with no migration step. Existing clients keep using `/v1/models` and `/v1/chat`; added probe fields are optional. Rollback is removing the new dashboard endpoint and reverting probe/display changes.

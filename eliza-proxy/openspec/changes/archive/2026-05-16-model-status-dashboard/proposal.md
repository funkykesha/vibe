## Why

Startup model probing currently marks many catalog models as unavailable even though later chat requests can work. The startup display also moves and visually merges while probes run, making it hard to tell which models are healthy, slow, quota-limited, or genuinely unavailable.

## What Changes

- Separate catalog availability from probe health: models returned by `/v1/models` remain selectable, while probe status is reported as health metadata.
- Replace binary probe results with `pending`, `success`, `warning`, and `error` states.
- Run probes in the background with bounded concurrency and timeout policy based on live measurements.
- Render a stable startup status dashboard that seeds all models as pending, updates in place, and avoids terminal line merging.
- Add a lightweight root page that shows model probe status after the server is running.
- Expose probe summary through HTTP endpoints so terminal and browser displays use the same source of truth.

## Capabilities

### New Capabilities
- `model-status-dashboard`: Browser-visible model status dashboard and HTTP probe status summary.

### Modified Capabilities
- `model-startup-logging`: Startup model status semantics, probe state display, progress accounting, and terminal rendering behavior.
- `auto-exit-after-probe`: Probe completion accounting must continue to work when probes run in the background with bounded concurrency.

## Impact

- Affected modules: `server.js`, `lib/eliza-client/probe.js`, `lib/eliza-client/index.js`, `lib/startup-display-manager.js`, and `lib/formatting/model-status-formatter.js`.
- Affected HTTP behavior: `/`, `/v1/models`, `/v1/health`, and a new probe status summary endpoint.
- Affected tests: eliza client probe tests, startup display tests, and HTTP route tests.
- No breaking changes to `/v1/chat` streaming format.

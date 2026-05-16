## 1. Probe State Foundation

- [x] 1.1 Add shared in-memory probe state with lifecycle `idle`, `running`, `complete`, provider grouping, summary counts, and per-model metadata.
- [x] 1.2 Attach probe metadata to `/v1/models` results without removing catalog models when probe status is `warning` or `error`.
- [x] 1.3 Update `/v1/health` to include probe lifecycle and summary counts.

## 2. Probe Execution

- [x] 2.1 Implement bounded concurrency in `runProbe()` with default concurrency `4`.
- [x] 2.2 Add timeout policy with default timeout and measured model/provider overrides.
- [x] 2.3 Map probe results to `success`, `warning`, and `error` with `kind`, `latencyMs`, `variant`, and `checkedAt`.
- [x] 2.4 Ensure `--exit-after-probe` waits for every model to reach final probe state, including `warning`.

## 3. Startup Terminal Display

- [x] 3.1 Seed the terminal display with the full model catalog as `pending` before applying probe updates.
- [x] 3.2 Buffer probe events that arrive before display seed and apply them after initialization.
- [x] 3.3 Update model status formatting for `pending`, `success`, `warning`, and `error`.
- [x] 3.4 Fix wrapping and rendered-line accounting so terminal updates do not shift or merge lines.
- [x] 3.5 Avoid cursor movement control codes for non-TTY output.

## 4. Browser Dashboard

- [x] 4.1 Add `GET /v1/probe-status` returning probe lifecycle, summary counts, and provider-grouped model statuses.
- [x] 4.2 Add `GET /` read-only HTML dashboard with provider groups, model rows, counts, latency, kind, and timestamps.
- [x] 4.3 Add dashboard polling that updates frequently while probe is running and slows after completion.
- [x] 4.4 Keep the dashboard read-only with no chat UI and no probe controls.

## 5. Tests and Verification

Sandbox note: manual `npm start` smoke check was executed, but this sandbox blocks listening sockets with `EPERM` on port bind.


- [x] 5.1 Add unit tests for probe classification, timeout policy, and concurrency limit.
- [x] 5.2 Add startup display tests for full pending seed, buffered updates, stable order, wrapping, and non-TTY output.
- [x] 5.3 Add HTTP tests for `/`, `/v1/probe-status`, `/v1/health`, and `/v1/models` probe metadata.
- [x] 5.4 Include `tests/startup-display.test.js` in `npm test`.
- [x] 5.5 Run `npm test` and a manual `npm start` smoke check.

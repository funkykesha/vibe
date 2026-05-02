## Why

TBank automation is high-risk because the available personal banking source is unofficial. This replacement stage isolates provider adapter contracts, mapping state, mocked contract tests, live local account fetch gate, and no-silent-write safety before any automation updates financial state.

## What Changes

- Define provider adapter boundary and normalized account shape.
- Add account mapping state machine: unmapped, candidate, confirmed, stale, conflict, ignored.
- Handle unmapped, ambiguous, hidden, missing, or no-balance accounts safely.
- Require mocked adapter contract tests.
- Require live local account fetch proof before live sync writes are enabled.
- Prevent silent financial changes from provider data.

## Capabilities

### New Capabilities

- `tbank-account-sync`: TBank provider adapter, account mapping, validation gates, and safe sync-write boundary.

## Impact

- Depends on backend foundation.
- Live write sync remains gated until mapping and live fetch proof pass.

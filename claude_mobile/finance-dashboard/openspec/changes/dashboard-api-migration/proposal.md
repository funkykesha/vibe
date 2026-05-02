## Why

The dashboard cannot support Telegram, snapshots, or deployment while browser localStorage remains the source of truth. This change migrates dashboard data access to the backend after the backend foundation exists, while preserving current salary and capital behavior.

## What Changes

- Add initial API read/import path from current localStorage shape.
- Replace whole-object localStorage persistence with API reads and partial writes.
- Add loading, error, retry, and stale-response handling.
- Preserve salary and capital calculations.
- Keep salary history out of migration because salary inputs are not currently persisted.

## Capabilities

### New Capabilities

- `dashboard-api-migration`: Dashboard state migration from localStorage to backend APIs with safe loading/error/race behavior.

## Impact

- Production dashboard data access changes, but formulas and visible calculations should not.
- Requires `backend-foundation`.

## Why

Salary events and snapshots are core product memory, but they were previously mixed into broad product and automation changes. This replacement stage defines persisted salary records, explicit snapshots, captured context, totals, comparison behavior, and history readiness.

## What Changes

- Add salary event records for saved salary calculations.
- Add explicit app-created snapshots with versioned payloads.
- Capture settings/context needed to interpret historical totals.
- Store or expose snapshot totals and comparison behavior.
- Keep historical spreadsheet import separate from the MVP snapshot workflow.

## Capabilities

### New Capabilities

- `salary-events-snapshots`: Persisted salary events and explicit capital snapshots with totals and comparison semantics.

## Impact

- Requires backend foundation.
- Dashboard and Telegram can later call these APIs without redefining financial history semantics.

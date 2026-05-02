## Context

The product contract says salary events and snapshots are shared source-of-truth concepts. Archived research found current salary inputs are not persisted and historical spreadsheet import is messy enough to defer.

## Decisions

### D1: Salary events are new persisted records

Salary events are created from explicit saves, not inferred from existing localStorage.

### D2: Snapshots are explicit and versioned

Snapshots are created only by user request or confirmed ritual step. Each snapshot includes a payload version so future interpretation changes are trackable.

### D3: Capture interpretation context

Snapshot payloads include account balances plus settings needed to explain totals later, including currencies, USD rate, mortgage value, categories, and debts policy.

### D4: Totals are part of the snapshot contract

The system SHALL provide full capital, capital excluding debts, category totals, currency-adjusted totals, and mortgage-adjusted position for each snapshot.

### D5: Historical import remains deferred

Spreadsheet import may create reviewable candidates later. New app-created snapshots must work without imported history.

## Evidence

- Archived research `03-mini-spikes-and-context7.md` section 3.1: salary inputs are not persisted in current localStorage.
- Archived research section 3.12: historical files contain repeated headers, `NaN`, mixed sections, derived totals, and name/category drift.
- Decision log D4: snapshots are versioned financial interpretations.

## Handoff

Entry criteria:
- `backend-foundation` exists.
- `finance-product-contract` defines salary event and snapshot semantics.

Exit criteria:
- Dashboard and Telegram can create salary events/snapshots through stable contracts.
- History UI can rely on at least two comparable snapshots.
- Historical import remains explicitly outside this stage.

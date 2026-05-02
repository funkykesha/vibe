## 1. Salary Events

- [ ] 1.1 Add salary event schema/API for date, type, gross, deductions, net, and distribution.
- [ ] 1.2 Save events only from explicit user action.
- [ ] 1.3 Validate event types such as 5th payday, 20th payday, vacation, bonus, and other.

## 2. Snapshots

- [ ] 2.1 Add explicit snapshot creation API.
- [ ] 2.2 Capture account balances, settings context, label/timestamp, and payload version.
- [ ] 2.3 Provide snapshot totals for capital, debts policy, categories, currencies, and mortgage-adjusted position.

## 3. Comparison And History Readiness

- [ ] 3.1 Add comparison behavior for two snapshots.
- [ ] 3.2 Expose enough data for a future history timeline.
- [ ] 3.3 Keep historical import out of MVP implementation.

## 4. Verification

Entry criteria:
- `backend-foundation` and `finance-product-contract` define shared state and snapshot semantics.
- Salary calculations remain available from the dashboard or API contract.

Exit criteria:
- Salary events and app-created snapshots are persisted explicitly.
- Future history UI can rely on captured totals and context without historical import.

- [ ] 4.1 Verify no snapshot is created by a plain account edit.
- [ ] 4.2 Verify totals are explainable from captured context.
- [ ] 4.3 Verify comparison works with two app-created snapshots.
- [ ] 4.4 Run `openspec status --change "salary-events-snapshots"`.

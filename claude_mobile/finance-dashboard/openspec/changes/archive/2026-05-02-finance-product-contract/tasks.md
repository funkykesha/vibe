## 1. Product Contract

- [x] 1.1 Confirm the four rituals and their ordering are reflected in later stage plans.
- [x] 1.2 Confirm dashboard and Telegram responsibilities are not duplicated across implementation changes.
- [x] 1.3 Confirm source-of-truth concepts cover accounts, settings, salary events, snapshots, and provider mappings.
- [x] 1.4 Confirm the product remains single-user and excludes automatic transfers, broad bank automation, and mandatory OCR.

## 2. Handoff Verification

Entry criteria:
- Archived research gate and rebuild inventory have been read.
- Replacement implementation stages are available for cross-checking.

Exit criteria:
- Product meaning is stable enough for UX, backend, salary/snapshot, Telegram, and provider stages to implement without redefining scope.
- Deferred and dropped scope is explicit.

- [x] 2.1 Verify `dashboard-ritual-ux` can implement visual hierarchy without redefining product meaning.
- [x] 2.2 Verify `backend-foundation`, `salary-events-snapshots`, and `telegram-finance-assistant` can implement shared-state behavior against this contract.
- [x] 2.3 Run `openspec status --change "finance-product-contract"`.

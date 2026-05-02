## 1. Provider Adapter

- [ ] 1.1 Define normalized provider account contract.
- [ ] 1.2 Implement TBank adapter behind that contract with explicit timeouts and provider errors.
- [ ] 1.3 Keep raw provider responses available only for diagnostics, not business decisions.

## 2. Mapping State

- [ ] 2.1 Add mapping states: unmapped, candidate, confirmed, stale, conflict, ignored.
- [ ] 2.2 Generate candidates without treating name-only matches as confirmed.
- [ ] 2.3 Require user confirmation before provider ID mappings can update balances.
- [ ] 2.4 Mark missing provider accounts stale rather than deleting internal accounts.

## 3. Gates And Verification

Entry criteria:
- `backend-foundation` has account persistence and config.
- Account mapping storage shape is approved.

Exit criteria:
- Mocked adapter and live local fetch gates pass before live writes are enabled.
- Unmapped or unsafe provider data cannot silently change financial balances.

- [ ] 3.1 Add mocked adapter contract tests.
- [ ] 3.2 Perform live local account fetch before enabling live sync writes.
- [ ] 3.3 Verify unmapped, ambiguous, currency mismatch, and no-balance accounts do not write.
- [ ] 3.4 Run `openspec status --change "tbank-account-sync"`.

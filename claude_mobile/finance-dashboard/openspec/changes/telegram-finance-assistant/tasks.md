## 1. Bot Foundation

- [ ] 1.1 Add local polling bot process with configured token.
- [ ] 1.2 Enforce configured Telegram user whitelist.
- [ ] 1.3 Return safe response for unauthorized users without financial data.

## 2. Commands

- [ ] 2.1 Add `/summary` from backend shared state with freshness.
- [ ] 2.2 Add safe manual `/update` parse, match, confirmation, and write flow.
- [ ] 2.3 Add `/snapshot` flow when snapshot API is available, or an honest unavailable state before then.

## 3. Verification

Entry criteria:
- `backend-foundation` exposes shared account/settings state.
- Snapshot command availability is known from `salary-events-snapshots`.

Exit criteria:
- Authorized user can read summaries and perform confirmed manual writes.
- Provider refresh behavior remains outside this change until `tbank-account-sync` owns it.

- [ ] 3.1 Verify unauthorized users cannot read or write data.
- [ ] 3.2 Verify ambiguous manual updates do not write balances.
- [ ] 3.3 Verify dashboard sees bot-created manual updates through shared state.
- [ ] 3.4 Run `openspec status --change "telegram-finance-assistant"`.

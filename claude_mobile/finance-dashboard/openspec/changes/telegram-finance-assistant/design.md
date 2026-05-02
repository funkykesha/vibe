## Context

The product contract defines Telegram as the quick mobile action surface. This stage implements local polling first and avoids deployment-specific webhook behavior.

## Decisions

### D1: Use whitelist authorization

The bot SHALL only respond to configured Telegram user IDs. Unauthorized messages do not expose financial data.

### D2: Local polling first

Polling is the first implementation mode. Webhook mode depends on deployment host, HTTPS URL, secret token, and pending-update policy.

### D3: Manual updates require confirmation

The bot SHALL never change balances from ambiguous or fuzzy commands without showing the matched account and requested value.

### D4: Summary reads shared state

`/summary` reads backend accounts/settings and reports key totals plus freshness indicators.

## Evidence

- Archived research `03-mini-spikes-and-context7.md` section 3.5: python-telegram-bot supports polling/conversation state; Telegram Bot API webhook requires HTTPS URL, secret token, and pending-update policy.
- TBank guided auth remains dependent on provider storage/mapping evidence from section 3.3.

## Handoff

Entry criteria:
- `backend-foundation` exposes shared accounts/settings.
- `finance-product-contract` defines Telegram responsibility.

Exit criteria:
- Authorized Telegram user can read summary and perform confirmed manual updates.
- Snapshot command either works through `salary-events-snapshots` or is explicitly unavailable.
- Webhook deployment remains deferred to `deployment-readiness`.

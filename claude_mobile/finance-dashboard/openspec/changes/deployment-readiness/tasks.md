## 1. Platform And Storage

- [ ] 1.1 Select deployment target and process model.
- [ ] 1.2 Configure managed Postgres through `DATABASE_URL`.
- [ ] 1.3 Reject or explicitly justify any deployed SQLite usage with persistent disk and backup plan.

## 2. Secrets And Access

- [ ] 2.1 Configure secrets through platform environment variables.
- [ ] 2.2 Define deployed dashboard/API access boundary for the single authorized user.
- [ ] 2.3 Verify `.env` files are not part of deployment artifacts.

## 3. Backups And Telegram Webhook

- [ ] 3.1 Define backup schedule and restore procedure.
- [ ] 3.2 Configure Telegram webhook with HTTPS URL, secret token, and pending-update policy.
- [ ] 3.3 Define local polling to webhook transition steps.

## 4. Verification

Entry criteria:
- Local backend, dashboard API migration, Telegram assistant, and provider/snapshot flows required for deployment are working.
- Deployment target and process model are selected.

Exit criteria:
- Deployed persistence uses managed storage or an explicitly approved persistent alternative.
- Secrets, access boundary, backups, restore, and webhook behavior are verified.

- [ ] 4.1 Verify deployed app connects to managed Postgres.
- [ ] 4.2 Verify restart does not lose financial data.
- [ ] 4.3 Verify webhook receives authorized commands only.
- [ ] 4.4 Run `openspec status --change "deployment-readiness"`.

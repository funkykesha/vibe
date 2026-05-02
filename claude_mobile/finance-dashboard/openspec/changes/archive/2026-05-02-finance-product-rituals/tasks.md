## 1. Product Alignment

- [ ] 1.1 Review the existing `finance-automation-system` change and map each technical stage to the ritual-first product model
- [ ] 1.2 Define the MVP sequence for salary day, quick capital refresh, progress check, and model maintenance rituals
- [ ] 1.3 Document which current spreadsheet concepts map to accounts, categories, deductions, salary events, and snapshots

## 2. Shared Source of Truth

- [ ] 2.1 Define persisted account, settings, salary event, snapshot, and provider mapping fields needed by all product surfaces
- [ ] 2.2 Define how dashboard, Telegram bot, and sync providers read and update the shared state
- [ ] 2.3 Verify that browser `localStorage` is no longer the source of truth after API migration
- [ ] 2.4 Verify that updates from any surface are visible from every other surface

## 3. Salary Ritual

- [ ] 3.1 Preserve the current salary distribution inputs, deduction logic, category percentage validation, and copy output
- [ ] 3.2 Add a saved salary event concept for 5th, 20th, vacation, bonus, or other salary event types
- [ ] 3.3 Add a completion path that leads from reviewed salary calculation to balance updates and optional snapshot

## 4. Capital Refresh Ritual

- [ ] 4.1 Add an automated refresh action for supported TBank accounts with changed-balance reporting
- [ ] 4.2 Add safe manual account update behavior for non-automated accounts
- [ ] 4.3 Add account matching safeguards so ambiguous or unmapped accounts are never updated silently

## 5. Dashboard Cockpit

- [ ] 5.1 Keep the salary area focused on careful calculation, review, and export of the distribution plan
- [ ] 5.2 Keep the capital area focused on account review, bank grouping, category totals, currency conversion, and mortgage-adjusted position
- [ ] 5.3 Add a history area for snapshot timeline and snapshot comparison
- [ ] 5.4 Keep settings focused on maintaining categories, deductions, accounts, currencies, USD rate, mortgage balance, and provider mappings

## 6. Telegram Assistant

- [ ] 6.1 Add `/summary` behavior that returns current key totals and freshness information
- [ ] 6.2 Add `/refresh` behavior that triggers supported automated account sync and reports results
- [ ] 6.3 Add `/update` behavior that confirms matched manual account updates before writing balances
- [ ] 6.4 Add `/snapshot` behavior that creates an explicit snapshot and returns key totals
- [ ] 6.5 Add guided placeholders for `/auth_tbank` and `/photo` without silently changing financial data

## 7. History And Progress

- [ ] 7.1 Create explicit snapshot behavior that captures current balances, interpretation settings, and timestamp or label
- [ ] 7.2 Calculate snapshot totals for full capital, capital excluding debts, categories, currency-adjusted values, and mortgage-adjusted position
- [ ] 7.3 Add comparison behavior for snapshot deltas and movement direction
- [ ] 7.4 Keep historical spreadsheet import optional so new app-created snapshots work without import

## 8. Verification

- [ ] 8.1 Verify the salary day ritual end-to-end from calculation through saved event and snapshot
- [ ] 8.2 Verify quick capital refresh from TBank sync, manual update, summary, and dashboard visibility
- [ ] 8.3 Verify progress review with at least two snapshots and visible deltas
- [ ] 8.4 Verify that out-of-scope behavior remains absent: multi-user auth, automatic transfers, and broad non-TBank automation

## 1. Theme Foundation

- [ ] 1.1 Define Swiss Finance, Dark Finance, and System theme tokens.
- [ ] 1.2 Replace global mono styling with sans-first text and tabular numerals where needed.
- [ ] 1.3 Persist theme preference without changing financial data.

## 2. Navigation And Screens

- [ ] 2.1 Add compact navigation for `Ритуалы`, `Капитал`, `История`, and `Настройки`.
- [ ] 2.2 Make `Ритуалы` the default first screen.
- [ ] 2.3 Add history and settings shells with honest empty/disabled states.

## 3. Ritual Workspace

- [ ] 3.1 Recompose salary inputs, deductions, net salary, and distribution into one visible-step workspace.
- [ ] 3.2 Add compact capital strip from current derived totals.
- [ ] 3.3 Keep finish actions visible while backend-dependent actions remain safe placeholders if unavailable.

## 4. Verification

Entry criteria:
- `finance-product-contract` defines ritual meaning and surface responsibilities.
- Current dashboard calculations are available as the behavior baseline.

Exit criteria:
- UX implementation preserves salary and capital calculations.
- Backend-dependent actions have honest placeholders or disabled states until their APIs exist.

- [ ] 4.1 Verify desktop layout uses two columns.
- [ ] 4.2 Verify mobile layout has no horizontal scroll.
- [ ] 4.3 Verify salary and capital calculations match the pre-redesign dashboard.
- [ ] 4.4 Run `openspec status --change "dashboard-ritual-ux"`.

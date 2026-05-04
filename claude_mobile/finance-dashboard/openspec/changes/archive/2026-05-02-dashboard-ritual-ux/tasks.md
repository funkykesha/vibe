## 1. Theme Foundation

- [x] 1.1 Define Swiss Finance, Dark Finance, and System theme tokens.
- [x] 1.2 Replace global mono styling with sans-first text and tabular numerals where needed.
- [x] 1.3 Persist theme preference without changing financial data.

## 2. Navigation And Screens

- [x] 2.1 Add compact navigation for `Ритуалы`, `Капитал`, `История`, and `Настройки`.
- [x] 2.2 Make `Ритуалы` the default first screen.
- [x] 2.3 Add history and settings shells with honest empty/disabled states.

## 3. Ritual Workspace

- [x] 3.1 Recompose salary inputs, deductions, net salary, and distribution into one visible-step workspace.
- [x] 3.2 Add compact capital strip from current derived totals.
- [x] 3.3 Keep finish actions visible while backend-dependent actions remain safe placeholders if unavailable.

## 4. Verification

Entry criteria:
- `finance-product-contract` defines ritual meaning and surface responsibilities.
- Current dashboard calculations are available as the behavior baseline.

Exit criteria:
- UX implementation preserves salary and capital calculations.
- Backend-dependent actions have honest placeholders or disabled states until their APIs exist.

- [x] 4.1 Verify desktop layout uses two columns.
- [x] 4.2 Verify mobile layout has no horizontal scroll.
- [x] 4.3 Verify salary and capital calculations match the pre-redesign dashboard.
- [x] 4.4 Run `openspec status --change "dashboard-ritual-ux"`.

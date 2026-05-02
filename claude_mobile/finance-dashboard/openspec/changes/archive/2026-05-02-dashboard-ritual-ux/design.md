## Context

Source requirements come from `finance-product-design-system`. The current app is single-file React/Babel with inline Tailwind classes, mobile-narrow layout, and local calculations.

## Decisions

### D1: Theme changes are token-driven

Swiss Finance, Dark Finance, and System modes SHALL share the same layout and component structure. Theme mode changes are semantic token changes, not separate UI branches.

### D2: The first screen is the ritual workspace

The dashboard opens to `Ритуалы` with `Зарплатный день` as the active MVP workflow.

### D3: Capital context stays compact on the ritual screen

The ritual screen shows headline capital context, not detailed account management or charts.

### D4: History and settings are shells where data is unavailable

`История` SHALL not fabricate chart data before reliable snapshots exist. Settings remains focused on maintaining the finance model.

### D5: Layout must work for repeated expert use

Desktop uses an efficient two-column ritual workspace; mobile uses a single readable flow with no horizontal scrolling.

## Evidence

- Archived research `03-mini-spikes-and-context7.md` section 3.7: Tailwind responsive variants, dark mode variants, and theme tokens; Babel standalone feasibility.
- Archived research section 3.13: current single-file constraints and recommendation to split tokens/navigation/layout from backend-dependent history.

## Handoff

Entry criteria:
- `finance-product-contract` defines ritual order and surface responsibilities.
- No backend API dependency is required for this UX stage.

Exit criteria:
- Salary and capital calculations remain behaviorally unchanged.
- History and snapshot actions do not claim working backend behavior.
- The next API migration stage can replace data access without redoing the UX contract.

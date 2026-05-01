## 1. Theme Foundation

- [ ] 1.1 Define Swiss Finance light theme tokens for background, surface, border, text, muted text, accent, positive, warning, and danger.
- [ ] 1.2 Define Dark Finance theme tokens with the same semantic roles.
- [ ] 1.3 Add `System`, `Light`, and `Dark` theme state with persisted preference.
- [ ] 1.4 Replace global mono body styling with a sans-first font stack and tabular number styling only where numbers need alignment.

## 2. Product Navigation

- [ ] 2.1 Replace the current three-tab header with compact top navigation for `Ритуалы`, `Капитал`, `История`, and `Настройки`.
- [ ] 2.2 Make `Ритуалы` the default section.
- [ ] 2.3 Add a compact theme selector that does not dominate the header.

## 3. Ritual Workspace

- [ ] 3.1 Create the `Зарплатный день` ritual header with current date/payday context and next-action copy.
- [ ] 3.2 Add the compact capital strip using existing derived capital totals.
- [ ] 3.3 Recompose existing salary inputs, deductions, net salary, and distribution into one workspace with visible steps.
- [ ] 3.4 Add a status column showing salary input, deductions, distribution total, capital update, and snapshot status.
- [ ] 3.5 Keep finish actions visible: copy distribution, go to capital, and create snapshot placeholder if snapshots are not implemented yet.

## 4. Capital, History, Settings Shell

- [ ] 4.1 Move detailed account editing into the `Капитал` section while preserving current account calculations.
- [ ] 4.2 Add a `История` shell that communicates history is based on future reliable snapshots and does not invent chart data.
- [ ] 4.3 Keep settings focused on model maintenance: categories, percentages, deductions, and future account metadata.

## 5. Responsive Verification

- [ ] 5.1 Verify desktop layout uses two columns for the ritual workspace.
- [ ] 5.2 Verify mobile layout stacks into one readable flow with no horizontal scroll.
- [ ] 5.3 Verify both Swiss Finance and Dark Finance meet readable contrast for text, borders, controls, and focus states.
- [ ] 5.4 Verify salary and capital calculations match the current implementation after the visual redesign.

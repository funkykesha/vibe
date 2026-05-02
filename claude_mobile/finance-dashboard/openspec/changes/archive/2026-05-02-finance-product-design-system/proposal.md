## Why

The finance product needs a fixed design direction before deeper implementation continues. The current interface works as a compact dark table, but the target product is a ritual-first financial assistant that should feel minimal, calm, and fast for repeated salary-day use.

## What Changes

- Define the dashboard's product design system around a salary-day ritual as the primary MVP flow.
- Establish Swiss Finance as the primary visual theme and Dark Finance as a secondary theme.
- Define a compact top navigation for `Ритуалы`, `Капитал`, `История`, and `Настройки`.
- Define the first screen as a ritual workspace with a compact capital strip.
- Define the salary-day workspace as one page with visible steps, not a wizard.
- Define layout rules for desktop and mobile: two-column desktop, single-flow mobile.
- Capture approximate wireframes for the main ritual screen.
- Defer charts from the first ritual screen while reserving them for history and progress views.

## Capabilities

### New Capabilities

- `product-design-system`: Defines visual themes, layout structure, navigation, and approximate screen composition for the finance dashboard.

### Modified Capabilities

None. This change introduces design requirements and does not alter existing product behavior specs.

## Impact

- Existing `index.html`: future UI changes should migrate the current tabs and tables toward the new ritual workspace while preserving salary and capital calculations.
- Design tokens: future code should support light, dark, and system theme modes.
- Product specs: future dashboard, capital, history, and settings work should follow this visual and interaction structure.
- Out of scope: code implementation, backend changes, Telegram bot UI, detailed chart design, and pixel-perfect high-fidelity screens.

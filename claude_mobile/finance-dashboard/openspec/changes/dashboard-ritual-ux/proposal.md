## Why

The current dashboard works as a compact dark local tool, but the replacement roadmap needs a focused UX stage that can improve ritual flow without depending on backend, bot, or snapshot APIs.

## What Changes

- Introduce theme tokens for Swiss Finance light, Dark Finance, and system preference.
- Replace the current tab hierarchy with compact navigation for `Ритуалы`, `Капитал`, `История`, and `Настройки`.
- Make `Ритуалы` and `Зарплатный день` the first screen.
- Add compact capital context to the ritual screen while preserving salary calculations.
- Add history and settings shells without inventing unavailable snapshot data.
- Define desktop and mobile responsive layout expectations.

## Capabilities

### New Capabilities

- `dashboard-ritual-ux`: Dashboard visual hierarchy, navigation, theme, ritual workspace, and responsive shell behavior.

## Impact

- Future production work is limited to dashboard UX and current derived data.
- Backend-dependent actions may appear only as disabled or placeholder states until their stages land.

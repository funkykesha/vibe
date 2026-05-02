## Why

The current finance dashboard is a local MVP that mirrors parts of a manual spreadsheet workflow, but the real product opportunity is broader: make recurring personal finance routines shorter, calmer, and more reliable. The future project should be defined as a ritual-first financial assistant before implementation continues, so backend, bot, history, and dashboard work all serve the same product shape.

## What Changes

- Introduce a product-level model where the core experience is the twice-monthly finance ritual around salary, balance updates, snapshots, and progress review.
- Define the dashboard as the analytical cockpit for full-picture review, salary distribution, capital overview, history, and settings.
- Define the Telegram bot as the mobile action surface for quick refreshes, manual balance updates, summaries, snapshots, and future guided auth/photo flows.
- Define a shared source of truth where accounts, settings, salary events, and capital snapshots live outside browser localStorage.
- Add history and progress concepts as first-class product capabilities, not just raw storage tables.
- Keep the product intentionally single-user and personal; do not introduce multi-user auth, bank-wide automation, or automatic transfers.

## Capabilities

### New Capabilities

- `finance-rituals`: Defines the main user rituals: salary day, quick capital refresh, progress check, and model maintenance.
- `dashboard-cockpit`: Defines the dashboard as the large-screen overview for salary, capital, history, and settings.
- `telegram-finance-assistant`: Defines Telegram bot behavior as the fast mobile interface for finance actions.
- `financial-source-of-truth`: Defines the persisted financial model shared by dashboard, bot, and future integrations.
- `capital-history-progress`: Defines snapshots, deltas, and progress review across capital, mortgage, currency, and categories.

### Modified Capabilities

None. There are no existing OpenSpec capability specs in this repository.

## Impact

- Product direction: reframes the app from a static dashboard into a ritual-first personal finance assistant.
- Existing dashboard: future changes should preserve the current salary and capital logic while moving persistence and history into a shared backend.
- Backend/API: future implementation should expose the shared source of truth to both dashboard and bot.
- Telegram bot: future implementation should prioritize quick operational actions over full analytical views.
- Data model: accounts, settings, salary events, and snapshots become core product concepts.
- Out of scope for this change: multi-user accounts, automatic money transfers, full banking integrations beyond TBank-first automation, and mandatory OCR.

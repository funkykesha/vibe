## Context

Source requirements come from `finance-product-rituals` and the rebuilt inventory. The current dashboard is useful but local; the target product is a single-user ritual assistant that makes recurring salary and capital updates reliable.

## Decisions

### D1: Rituals are the product backbone

The product SHALL optimize for salary day, quick capital refresh, progress check, and model maintenance. Screens and integrations are supporting surfaces, not separate products.

### D2: Dashboard and Telegram have separate responsibilities

The dashboard owns analytical review, salary distribution, capital details, history, and settings. Telegram owns quick mobile actions: summary, manual update, snapshot, and later refresh/auth flows.

### D3: Browser local state is not the long-term source of truth

Accounts, settings, salary events, snapshots, and provider mappings are shared product concepts. Later backend and migration changes must make updates from one supported surface visible to the others.

### D4: Snapshots are explicit financial checkpoints

Snapshots capture an intentional interpretation of current finances. Edits alone do not create history.

### D5: Single-user does not mean unauthenticated public access

The product stays personal and single-user. Later backend and deployment stages must still define trusted local/deployed access boundaries.

## Evidence

- Inventory routing: `docs/superpowers/plans/rebuild-finance-spec-roadmap-inventory.md`.
- Archived decision log D4 and D6: snapshots are versioned interpretations; local-first still needs deployed access boundaries.
- This product-contract stage has no direct external library, API, provider, browser, or hosting dependency. External evidence is carried in the downstream implementation stages that depend on React/Tailwind, FastAPI/SQLAlchemy/Pydantic, python-telegram-bot, TBank fallback docs, deployment platforms, and OCR providers.

## Handoff

Entry criteria:
- Replacement change skeletons exist.
- The inventory accounts for the old product requirements.

Exit criteria:
- Product requirements are captured without implementation ownership.
- Later stages can cite this change for ritual ordering, surface split, single-user scope, salary event semantics, and snapshot semantics.

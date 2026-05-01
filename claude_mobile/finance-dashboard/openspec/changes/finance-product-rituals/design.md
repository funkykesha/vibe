## Context

The current project is a single-file React dashboard in `index.html`. It supports salary distribution, capital overview, settings, and local persistence through `localStorage`. The surrounding specs already point toward a future FastAPI backend, SQLite storage, Telegram bot, TBank synchronization, snapshots, and salary events.

This change fixes the product shape before deeper implementation: the future system is a ritual-first financial assistant. Its job is to make the recurring finance routine around the 5th and 20th calmer, shorter, and less error-prone while preserving a trustworthy view of capital over time.

The primary stakeholder is one user managing personal and family finances. The system can optimize for single-user speed, clarity, and control instead of generic SaaS patterns.

## Goals / Non-Goals

**Goals:**

- Define the product around recurring finance rituals rather than around isolated screens or integrations.
- Preserve the current dashboard's useful salary and capital concepts while giving them a clearer product role.
- Define the Telegram bot as a quick mobile action surface, not a replacement for analytical dashboard views.
- Establish the shared financial source of truth that future dashboard, bot, and sync work must use.
- Make history and progress review first-class product outcomes.

**Non-Goals:**

- Implement code in this change.
- Redesign the visual UI in pixel detail.
- Add multi-user support, full authentication, automatic transfers, or broad bank integrations.
- Make OCR mandatory for MVP.
- Replace the current `index.html` dashboard framework with a build system.

## Decisions

### D1: Use ritual-first product framing

The system will be designed around a small number of recurring rituals: salary day, quick capital refresh, progress check, and model maintenance.

Rationale: this matches the actual workflow described by the current tables and specs. It prevents the project from becoming a generic account tracker and keeps implementation choices tied to user relief.

Alternative considered: dashboard-first framing. That is simpler to explain technically, but it hides the reason the bot, snapshots, and salary events matter.

### D2: Keep dashboard and bot as complementary surfaces

The dashboard will own full-picture review, detailed salary calculations, capital breakdowns, history, and settings. Telegram will own fast actions: refresh, update, summary, snapshot, and guided flows.

Rationale: the dashboard is better for complex inspection; Telegram is better for action in the moment. Merging these roles would either overload the bot or make mobile updates too heavy.

Alternative considered: make Telegram the main interface. That would reduce desktop dependency but make analytical review, category editing, and history harder to understand.

### D3: Treat shared persisted finance data as the product memory

Accounts, settings, salary events, and snapshots will be treated as shared product concepts used by all surfaces.

Rationale: the current `localStorage` state is enough for a static MVP but cannot support bot updates, sync, history, or future deployment. A shared source of truth also lowers the risk of conflicting numbers.

Alternative considered: keep dashboard state local and sync only selected values. That would preserve the existing implementation longer but make reliability worse as soon as Telegram and TBank are introduced.

### D4: Make snapshots explicit user checkpoints

Capital history will advance through explicit snapshots created after meaningful updates, especially around salary rituals.

Rationale: the existing workflow treats dates as meaningful financial checkpoints. Automatic snapshots on every edit would create noise and make progress harder to interpret.

Alternative considered: create a snapshot after every balance change. That would be more automatic but would blur intentional review moments with transient edits.

### D5: Defer broad automation until the manual ritual is stable

TBank automation is part of the near-term future, but other banks remain manual through Telegram or dashboard until the ritual works end-to-end.

Rationale: the product value comes from a reliable routine, not from maximum integration count. Manual commands are still a large improvement over spreadsheet editing.

Alternative considered: prioritize all-bank automation. That would increase dependency risk and delay the core workflow.

## Risks / Trade-offs

- Product scope drift into a generic finance app -> Keep requirements anchored to the four rituals and single-user context.
- Telegram commands become too clever or ambiguous -> Require confirmation for fuzzy account updates and keep analytical review in the dashboard.
- Snapshots become inconsistent if created before balances are updated -> Present snapshot as the final step of the salary/update ritual.
- Existing spreadsheet concepts contain messy naming and historical exceptions -> Preserve current categories where possible and treat cleanup as model maintenance, not hidden migration magic.
- Product specs overlap with technical `finance-automation-system` change -> Keep this change product-level and use the technical change for implementation architecture.

## Migration Plan

1. Use these specs as the product contract for future implementation planning.
2. Align the existing `finance-automation-system` technical change with the ritual-first framing before coding.
3. Implement the shared source of truth before moving dashboard persistence away from `localStorage`.
4. Add Telegram actions and explicit snapshots after the backend can hold current account/settings state.
5. Add history/progress UI after snapshots are reliable.

Rollback is conceptual for this change: if the product framing proves wrong, revise these specs before implementation rather than carrying the mismatch into code.

## Open Questions

- Should historical spreadsheet data be imported into snapshots immediately, or should history start from the first reliable app-created snapshot?
- How much confirmation should Telegram require for repeated manual updates once account matching becomes familiar?
- Should salary events be created primarily from dashboard flows, Telegram flows, or both?

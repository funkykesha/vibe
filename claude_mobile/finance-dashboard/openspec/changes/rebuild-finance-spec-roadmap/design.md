## Context

The research gate has been archived and promoted `research-quality-gate` into the baseline specs. The active finance changes remain pre-research planning artifacts:

- `finance-product-rituals` defines the product model and broad surface contracts.
- `finance-product-design-system` defines the first dashboard design direction.
- `finance-automation-system` defines a broad technical pipeline for backend, API migration, TBank, Telegram, history, salary events, OCR, and deployment.

Those changes are useful source material, but they are not implementation-ready as a set. They overlap in scope, use different stage boundaries, and combine product contracts with technical execution details. This change creates the spec contract and task plan for rewriting them into a smaller, ordered set of implementation changes.

## Goals / Non-Goals

**Goals:**

- Convert the post-research findings into a concrete OpenSpec roadmap.
- Define the target grouping for future finance implementation changes.
- Require handoff gates between changes so every stage starts from verified artifacts.
- Preserve the ritual-first product direction and the dashboard design direction while making stage boundaries clearer.
- Carry Context7 or fallback-source evidence forward whenever a stage depends on external libraries, APIs, or hosting behavior.

**Non-Goals:**

- Do not implement backend, bot, TBank sync, OCR, deployment, or dashboard code.
- Do not create high-fidelity UI comps.
- Do not solve every future implementation detail inside this meta-change.
- Do not keep the old broad planning changes as direct implementation queues after the roadmap rebuild is complete.

## Decisions

### D1: Treat the old active changes as inputs, then replace or archive them

`finance-product-rituals`, `finance-product-design-system`, and `finance-automation-system` should be reviewed as source material, not executed directly. The rebuilt roadmap should create narrower implementation changes and then either archive the old broad changes or update them so they no longer duplicate the new queue.

Alternative: keep all three changes active and add notes. Rejected because future implementers would still see multiple competing task lists.

### D2: Group implementation by independently verifiable product states

The target sequence is:

1. Product contract normalization.
2. Dashboard ritual UX redesign.
3. Backend foundation and config.
4. Dashboard API migration.
5. Salary events and snapshots.
6. Telegram assistant without TBank automation.
7. TBank sync and account mapping.
8. Deployment readiness.
9. OCR/photo flow as a deferred optional change.

Each stage must leave the app in a coherent state and provide verification evidence before the next stage starts.

Alternative: follow the original `finance-automation-system` stage order exactly. Rejected because it puts integration work too close to foundational data migration and does not separate the UX redesign from API migration risk.

### D3: Put manual shared-state flows before automated provider sync

The dashboard, backend, snapshots, salary events, and Telegram manual update flows should be specified before TBank sync. This makes account identity, shared state, and explicit checkpoints testable before introducing external provider ambiguity.

Alternative: implement TBank early to show visible automation sooner. Rejected because the main TBank risk is safe mapping and silent-update prevention, which depends on a stable internal account model.

### D4: Require handoff artifacts between specs

Every rebuilt implementation change must define:

- Entry criteria.
- Exit criteria.
- Verification commands or manual checks.
- Data contract changes.
- User-visible state after completion.
- Follow-up spec changes required before the next stage.

Alternative: rely on tasks only. Rejected because cross-stage handoffs are where the current changes are most ambiguous.

### D5: Preserve research evidence references, not research prose

The rebuilt specs should not paste the archived research documents wholesale. They should reference the research gate and carry forward only the evidence that affects the stage, especially Context7 or fallback-source checks for FastAPI, SQLAlchemy, Pydantic settings, python-telegram-bot, deployment, OCR, React, Tailwind, browser storage/API behavior, and TBank provider documentation.

Alternative: duplicate all research notes into every spec. Rejected because duplicated evidence will drift and make reviews noisy.

## Risks / Trade-offs

- Rebuilding specs delays visible product work -> Mitigation: keep this change limited to OpenSpec artifacts and make the first implementation change clear.
- Old changes may still contain useful details after archive -> Mitigation: archive only after replacement changes preserve or intentionally drop their requirements.
- Stage boundaries may still be too coupled -> Mitigation: tasks include a dependency review before old changes are retired.
- Context7 may not cover a dependency -> Mitigation: the rebuilt spec must record fallback source, retrieval date, confidence level, and impact.

## Migration Plan

1. Read the archived research gate and active finance changes.
2. Create or update OpenSpec changes for the rebuilt stage sequence.
3. Move requirements from broad planning changes into the narrow replacement changes.
4. Add entry criteria, exit criteria, and handoff artifacts to each replacement change.
5. Verify no requirement from the active changes is lost without an explicit drop/defer decision.
6. Archive or neutralize superseded broad changes.

Rollback is conceptual: if the rebuilt roadmap is rejected, keep the existing active changes and archive this meta-change without touching production code.

## Open Questions

1. Should product contract normalization and dashboard UX be one implementation change or two separate changes if both only affect `index.html` at first?
2. Should deployment readiness target Railway, Render, local-only first, or a provider-neutral deployment spec?
3. Should historical spreadsheet import be a deferred standalone change or part of snapshots after the first snapshot UI exists?

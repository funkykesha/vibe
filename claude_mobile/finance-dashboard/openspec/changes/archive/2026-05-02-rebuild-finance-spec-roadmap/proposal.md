## Why

The research gate is complete, and the existing finance planning changes now need to be rebuilt into an implementation-ready OpenSpec roadmap. The current active changes still mix product direction, design direction, backend architecture, integrations, and future ideas, so implementation should not resume until those specs are normalized into reviewable stages with explicit handoffs.

## What Changes

- Introduce a post-research roadmap rebuild capability that governs how the existing finance specs are revised, split, deferred, or archived.
- Treat `finance-product-rituals`, `finance-product-design-system`, and `finance-automation-system` as audited inputs, not as direct implementation changes.
- Require the rebuilt roadmap to preserve the ritual-first product direction while separating product contracts, dashboard UX, backend foundation, API migration, history/salary events, Telegram assistant, TBank sync, deployment, and OCR into coherent implementation changes.
- Require every rebuilt implementation change to define entry criteria, exit criteria, verification steps, and handoff artifacts for the next change.
- Require external-dependency decisions from the research gate to carry forward with Context7 or fallback-source evidence where the next spec depends on external behavior.
- Explicitly defer production code changes until the roadmap rebuild is complete.

## Capabilities

### New Capabilities

- `finance-spec-roadmap`: Defines the post-research process for rewriting, splitting, ordering, and handing off the finance OpenSpec changes before implementation resumes.

### Modified Capabilities

- `research-quality-gate`: Clarifies that completed research verdicts must feed a concrete spec-roadmap rebuild before any implementation stage starts.

## Impact

- OpenSpec planning: creates a meta-change that rewrites the active finance change set into implementation-ready changes.
- Existing active changes: `finance-product-rituals`, `finance-product-design-system`, and `finance-automation-system` may be edited, split, superseded, or archived by the follow-up implementation tasks.
- Existing archived research: `openspec/changes/archive/2026-05-02-research-spec-quality-plan/` and `openspec/specs/research-quality-gate/spec.md` become required inputs.
- Code: no production app code changes are included in this change.

## 1. Research Inputs

- [ ] 1.1 Read `openspec/specs/research-quality-gate/spec.md` and the archived `openspec/changes/archive/2026-05-02-research-spec-quality-plan/` artifacts.
- [ ] 1.2 Read active changes `finance-product-rituals`, `finance-product-design-system`, and `finance-automation-system`.
- [ ] 1.3 Extract all current capabilities, requirements, task groups, stage names, non-goals, open questions, and dependency risks into a rebuild inventory.
- [ ] 1.4 Identify which requirements are product contracts, dashboard UX contracts, backend/API contracts, bot contracts, provider-sync contracts, deployment contracts, or future/OCR contracts.

## 2. Target Roadmap Definition

- [ ] 2.1 Define the replacement implementation sequence: product contract normalization, dashboard ritual UX redesign, backend foundation and config, dashboard API migration, salary events and snapshots, Telegram assistant, TBank sync, deployment readiness, and deferred OCR/photo flow.
- [ ] 2.2 For each replacement stage, record entry criteria, exit criteria, verification expectations, data/API/UI contracts, and handoff artifacts.
- [ ] 2.3 For each replacement stage with external dependencies, attach the relevant Context7 research record or fallback-source record from the archived research gate.
- [ ] 2.4 Record any requirement that will be intentionally deferred or dropped with rationale and migration impact.

## 3. Replacement OpenSpec Changes

- [ ] 3.1 Create or update a product contract change that owns finance rituals, shared source of truth, dashboard/bot responsibility split, single-user boundary, salary event semantics, and snapshot semantics.
- [ ] 3.2 Create or update a dashboard UX change that owns themes, top navigation, ritual-first first screen, capital context, history shell, settings shell, and responsive layout.
- [ ] 3.3 Create or update a backend foundation change that owns config, database, seed behavior, accounts/settings API, static serving, and local CORS.
- [ ] 3.4 Create or update a dashboard API migration change that owns replacing browser-local source of truth with REST reads/writes while preserving current salary and capital calculations.
- [ ] 3.5 Create or update a salary events and snapshots change that owns saved salary calculations, explicit snapshots, snapshot totals, comparison behavior, and history readiness.
- [ ] 3.6 Create or update a Telegram assistant change that owns `/summary`, safe manual `/update`, `/snapshot`, authorization boundary, and shared-state visibility before TBank automation.
- [ ] 3.7 Create or update a TBank sync change that owns provider adapter boundaries, account mapping, unmapped/ambiguous account handling, sync route or bot trigger, and no silent financial changes.
- [ ] 3.8 Create or update deferred deployment and OCR/photo changes or backlog notes so they are visible but do not block the MVP implementation sequence.

## 4. Superseded Change Cleanup

- [ ] 4.1 Compare every requirement in `finance-product-rituals` against the replacement changes and mark it preserved, moved, deferred, or dropped.
- [ ] 4.2 Compare every requirement in `finance-product-design-system` against the replacement changes and mark it preserved, moved, deferred, or dropped.
- [ ] 4.3 Compare every requirement in `finance-automation-system` against the replacement changes and mark it preserved, moved, deferred, or dropped.
- [ ] 4.4 Archive, narrow, or otherwise neutralize the old broad active changes so future implementers do not see duplicate competing task lists.

## 5. Verification

- [ ] 5.1 Verify `finance-spec-roadmap` requirements are covered by completed tasks or created artifacts.
- [ ] 5.2 Verify the modified `research-quality-gate` roadmap impact requirement has a concrete spec-rebuild output.
- [ ] 5.3 Verify no production app files were edited by this roadmap rebuild.
- [ ] 5.4 Run `openspec status --change "rebuild-finance-spec-roadmap"` and confirm the change is apply-ready.

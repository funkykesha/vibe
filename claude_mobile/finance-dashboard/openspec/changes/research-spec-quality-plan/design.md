## Context

The repository currently has two planning changes:

- `finance-product-rituals`: product-level specs for rituals, dashboard cockpit, Telegram assistant, shared source of truth, and history.
- `finance-automation-system`: technical plan for config, FastAPI backend, dashboard API migration, TBank sync, Telegram bot, snapshots, salary events, OCR, and deployment.
- `finance-product-design-system`: design-level specs for Swiss Finance and Dark Finance themes, ritual-first dashboard structure, compact capital context, responsive layout, and first-pass wireframes.

These changes are useful inputs, but they mix product direction, technical architecture, experience design, stage sequencing, and unresolved risks. Before implementation resumes, the project needs a research and audit gate that turns those inputs into decisions.

## Goals / Non-Goals

**Goals:**

- Audit all existing finance OpenSpec changes for conflicts, missing contracts, and unsafe assumptions.
- Audit `finance-product-design-system` against product rituals, automation stages, current UI constraints, and future implementation readiness.
- Run focused mini spikes where external dependencies or deployment choices can change architecture.
- Use Context7 documentation checks for external libraries, frameworks, APIs, and hosting platforms before making research verdicts that depend on them.
- Produce a decision log with a `keep`, `change`, `split`, or `drop` verdict for every currently planned stage.
- Produce roadmap impact notes that can drive a rebuilt implementation pipeline.
- Block implementation work until the gate is complete.

**Non-Goals:**

- Do not implement production backend, bot, sync, OCR, or dashboard behavior.
- Do not implement the UX redesign or produce high-fidelity UI comps in this change.
- Do not rewrite existing product specs directly inside this change.
- Do not choose a final one-change versus one-stage-per-change implementation structure without the research findings.

## Decisions

### D1: Treat this as a blocking gate for every stage

Research covers all currently planned stages, including `config-layer`. No implementation stage is considered ready until it receives an explicit verdict.

Alternative: allow `config-layer` to proceed early. Rejected because even config may change after deployment, process model, secrets, database, and provider research.

### D2: Use mini spikes only for architecture-changing risks

Spikes must be small and evidence-focused. They should prove or disprove assumptions about TBank API behavior, hosting/storage, Telegram process model, account mapping safety, and current dashboard data migration.

Alternative: analytical documentation only. Rejected because several risks depend on external behavior that can invalidate the architecture.

### D3: Use Context7 as the default documentation source for external dependencies

Research that depends on external libraries, frameworks, APIs, or hosting platforms should use Context7 to retrieve current documentation before assigning a final verdict. The researcher must resolve the Context7-compatible library ID before querying documentation. This applies to FastAPI, SQLAlchemy, Pydantic settings, python-telegram-bot, deployment platforms, storage options, and any documented provider or OCR dependency where Context7 has coverage.

If Context7 is unavailable or does not cover a dependency, the research output must record the fallback source, retrieval date, confidence level, and the reason it was used.

Alternative: rely on memory or generic web notes. Rejected because roadmap decisions need current, attributable documentation.

### D4: Treat experience design as an audited input, not implementation

This change audits existing specs and records research decisions. `finance-product-design-system` now defines the first design direction, so this gate should test that direction against product, technical, and current-code constraints before implementation.

Alternative: keep design fully outside the research gate. Rejected because the design spec can change implementation order, responsive scope, theme token work, and migration risk.

### D5: Require stage verdicts before roadmap rewrite

Each stage must be classified as `keep`, `change`, `split`, or `drop`, with rationale and downstream impact. The roadmap rewrite should depend on those verdicts, not on the original stage list.

Alternative: produce only a list of research tasks. Rejected because completed research must force changes to the plan where needed.

### D6: Prefer one implementation change per rebuilt stage

The expected implementation structure is one change per stage after research and design are complete. A single large implementation change remains possible only if the rebuilt roadmap proves stages are too tightly coupled.

Alternative: one giant implementation change. Rejected as the default because it would make review, rollback, and dependency control harder.

## Risks / Trade-offs

- Research can delay visible product work -> Mitigation: keep spikes narrow and require concrete verdicts.
- Audit findings may invalidate parts of existing specs -> Mitigation: treat current specs as inputs, not commitments.
- External provider research may be inconclusive -> Mitigation: record uncertainty and choose a conservative fallback stage.
- Context7 may not cover every dependency -> Mitigation: record the fallback source, date, and confidence level.
- Design work may later change the roadmap again -> Mitigation: audit `finance-product-design-system` now and record explicit roadmap impact before implementation starts.

## Migration Plan

1. Complete research and audit tasks for every current stage.
2. Record decision log entries and roadmap impact notes.
3. Audit `finance-product-design-system` and decide whether to keep, change, split, or defer design-system implementation work.
4. Rebuild the implementation roadmap using both research findings and design decisions.
5. Create implementation changes from the rebuilt roadmap, preferably one stage per change.

Rollback is not applicable because this change does not alter production code.

## Open Questions

1. After research and design complete, should the roadmap rewrite be one meta-change or the first implementation change?
2. Task 3.6 must decide which deployment target should be treated as primary during research: Railway, Render, local-only first, or another host.
3. Task 3.3 must decide what evidence is sufficient for TBank API acceptance: live account fetch, mocked adapter contract, or both.

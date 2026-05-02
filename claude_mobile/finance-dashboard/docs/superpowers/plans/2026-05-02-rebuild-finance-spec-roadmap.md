# Rebuild Finance Spec Roadmap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the active finance OpenSpec changes into a clear post-research implementation roadmap without touching production app code.

**Architecture:** This is a planning-only change. Treat the archived research gate and the three broad active finance changes as inputs, create narrower replacement OpenSpec changes, and then archive or neutralize superseded broad changes after every requirement is accounted for.

**Tech Stack:** OpenSpec CLI, Markdown, existing `finance-dashboard` single-file React project context.

---

## Files

- Read: `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/openspec/specs/research-quality-gate/spec.md`
- Read: `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/openspec/changes/archive/2026-05-02-research-spec-quality-plan/proposal.md`
- Read: `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/openspec/changes/archive/2026-05-02-research-spec-quality-plan/design.md`
- Read: `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/openspec/changes/archive/2026-05-02-research-spec-quality-plan/tasks.md`
- Read: `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/openspec/changes/finance-product-rituals/`
- Read: `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/openspec/changes/finance-product-design-system/`
- Read: `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/openspec/changes/finance-automation-system/`
- Modify/Create: replacement OpenSpec changes under `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/openspec/changes/`
- Do not modify: `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/index.html`

### Task 1: Build The Rebuild Inventory

**Files:**
- Create: `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/docs/superpowers/plans/rebuild-finance-spec-roadmap-inventory.md`

- [ ] **Step 1: Read baseline research contract**

Run:

```bash
sed -n '1,220p' openspec/specs/research-quality-gate/spec.md
```

Expected: output includes `Context7 documentation checks`, `Roadmap impact output`, and `Product design system audit`.

- [ ] **Step 2: Read archived research artifacts**

Run:

```bash
sed -n '1,220p' openspec/changes/archive/2026-05-02-research-spec-quality-plan/design.md
sed -n '1,220p' openspec/changes/archive/2026-05-02-research-spec-quality-plan/tasks.md
```

Expected: tasks show completed Context7 checks and completed verdict tasks for every stage.

- [ ] **Step 3: Create inventory document**

Create `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/docs/superpowers/plans/rebuild-finance-spec-roadmap-inventory.md` with sections:

```markdown
# Rebuild Finance Spec Roadmap Inventory

## Active Source Changes

- finance-product-rituals:
- finance-product-design-system:
- finance-automation-system:

## Stage Verdict Inputs

- config-layer:
- backend-foundation:
- dashboard-api-migration:
- tbank-sync:
- telegram-bot:
- history-snapshots:
- salary-events:
- vision-ocr:
- deployment:
- product-design-system:

## Requirement Routing

| Requirement | Source Change | Target Replacement Change | Decision |
|---|---|---|---|

## External Evidence Routing

| Dependency | Context7 or fallback source | Target Stage | Impact |
|---|---|---|---|

## Deferred Or Dropped Scope

| Scope | Decision | Rationale |
|---|---|---|
```

- [ ] **Step 4: Verify inventory exists**

Run:

```bash
test -f docs/superpowers/plans/rebuild-finance-spec-roadmap-inventory.md
```

Expected: command exits with status 0.

### Task 2: Create Replacement Change Skeletons

**Files:**
- Create/Modify: `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/openspec/changes/*`

- [ ] **Step 1: Create product contract change**

Run:

```bash
openspec new change "finance-product-contract"
```

Expected: `openspec/changes/finance-product-contract/.openspec.yaml` exists.

- [ ] **Step 2: Create dashboard UX change**

Run:

```bash
openspec new change "dashboard-ritual-ux"
```

Expected: `openspec/changes/dashboard-ritual-ux/.openspec.yaml` exists.

- [ ] **Step 3: Create backend foundation change**

Run:

```bash
openspec new change "backend-foundation"
```

Expected: `openspec/changes/backend-foundation/.openspec.yaml` exists.

- [ ] **Step 4: Create API migration change**

Run:

```bash
openspec new change "dashboard-api-migration"
```

Expected: `openspec/changes/dashboard-api-migration/.openspec.yaml` exists.

- [ ] **Step 5: Create later-stage changes**

Run:

```bash
openspec new change "salary-events-snapshots"
openspec new change "telegram-finance-assistant"
openspec new change "tbank-account-sync"
openspec new change "deployment-readiness"
openspec new change "deferred-ocr-photo-flow"
```

Expected: each new change directory exists.

### Task 3: Move Requirements Into Replacement Changes

**Files:**
- Modify: replacement change artifacts under `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/openspec/changes/`
- Read: old broad changes under `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/openspec/changes/finance-*`

- [ ] **Step 1: Route product requirements**

Move ritual, source-of-truth, salary event, snapshot semantics, dashboard/bot responsibility split, and single-user boundary requirements from `finance-product-rituals` into `finance-product-contract`.

Expected: `finance-product-contract` owns product meaning without backend implementation details.

- [ ] **Step 2: Route dashboard UX requirements**

Move theme, navigation, first screen, compact capital context, history shell, settings shell, and responsive layout requirements from `finance-product-design-system` into `dashboard-ritual-ux`.

Expected: `dashboard-ritual-ux` can be implemented against current `index.html` before API migration.

- [ ] **Step 3: Route backend/API requirements**

Move config, seed, DB, accounts/settings API, static serving, and CORS requirements from `finance-automation-system` into `backend-foundation`.

Expected: `backend-foundation` leaves dashboard behavior unchanged except static serving availability.

- [ ] **Step 4: Route migration and later-stage requirements**

Move localStorage-to-API migration into `dashboard-api-migration`, snapshots/salary events into `salary-events-snapshots`, bot manual flows into `telegram-finance-assistant`, provider sync into `tbank-account-sync`, deployment into `deployment-readiness`, and OCR/photo into `deferred-ocr-photo-flow`.

Expected: no replacement change combines unrelated product, UX, backend, provider, and deployment concerns.

### Task 4: Add Handoff Gates

**Files:**
- Modify: `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/openspec/changes/*/tasks.md`
- Modify: `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/openspec/changes/*/design.md`

- [ ] **Step 1: Add entry and exit criteria**

For every replacement change, add a `Handoff` or `Verification` section stating what must be true before the stage starts and what must be true before the next stage starts.

Expected: each replacement change has explicit entry and exit criteria.

- [ ] **Step 2: Add external evidence references**

For every replacement change depending on external behavior, cite the archived research Context7 or fallback-source evidence.

Expected: FastAPI/SQLAlchemy/Pydantic/python-telegram-bot/TBank/deployment/OCR decisions are not based on memory alone.

- [ ] **Step 3: Add no-production-code guard to this meta-change**

Verify `rebuild-finance-spec-roadmap/tasks.md` still states production app files must not be edited.

Run:

```bash
rg -n "no production|production app files|index.html" openspec/changes/rebuild-finance-spec-roadmap
```

Expected: output includes no-production-code requirement or task text.

### Task 5: Retire Superseded Broad Changes

**Files:**
- Modify/Archive: `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/openspec/changes/finance-product-rituals/`
- Modify/Archive: `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/openspec/changes/finance-product-design-system/`
- Modify/Archive: `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/openspec/changes/finance-automation-system/`

- [ ] **Step 1: Compare old and new requirements**

Run:

```bash
rg -n "Requirement:|### New Capabilities|Stage|TBank|Telegram|snapshot|salary|theme|API" openspec/changes/finance-product-rituals openspec/changes/finance-product-design-system openspec/changes/finance-automation-system openspec/changes/finance-product-contract openspec/changes/dashboard-ritual-ux openspec/changes/backend-foundation openspec/changes/dashboard-api-migration openspec/changes/salary-events-snapshots openspec/changes/telegram-finance-assistant openspec/changes/tbank-account-sync
```

Expected: every old requirement has a replacement, deferral, or drop decision in the inventory.

- [ ] **Step 2: Archive or neutralize old broad changes**

Use OpenSpec archive commands only after replacement changes preserve or explicitly defer/drop the old requirements.

Expected: `openspec status` no longer presents duplicate competing finance roadmaps.

### Task 6: Verify The Roadmap Rebuild

**Files:**
- Read: `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/openspec/changes/rebuild-finance-spec-roadmap/`
- Read: `/Users/agaibadulin/Desktop/projects/vibe/claude_mobile/finance-dashboard/openspec/changes/`

- [ ] **Step 1: Verify this change is apply-ready**

Run:

```bash
openspec status --change "rebuild-finance-spec-roadmap"
```

Expected: all artifacts complete.

- [ ] **Step 2: Verify production files were not changed**

Run:

```bash
git diff -- index.html
```

Expected: no output.

- [ ] **Step 3: Verify active roadmap is unambiguous**

Run:

```bash
openspec status --change "finance-product-contract"
openspec status --change "dashboard-ritual-ux"
openspec status --change "backend-foundation"
```

Expected: each replacement change reports artifact status and no command fails because of missing change directories.

- [ ] **Step 4: Commit planning artifacts**

Run:

```bash
git add openspec/changes/rebuild-finance-spec-roadmap docs/superpowers/plans/2026-05-02-rebuild-finance-spec-roadmap.md docs/superpowers/plans/rebuild-finance-spec-roadmap-inventory.md
git commit -m "docs: propose finance spec roadmap rebuild"
```

Expected: commit succeeds after all roadmap rebuild files are complete.

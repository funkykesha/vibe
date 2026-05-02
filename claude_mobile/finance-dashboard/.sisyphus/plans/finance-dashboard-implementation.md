# Finance Dashboard Sequential Implementation Plan

## TL;DR

> **Quick Summary**: Implement 4 changes sequentially to build a complete finance dashboard: product contract → UX foundation → backend → API integration. Each change follows apply → verify → archive pattern.
>
> **Deliverables**:
> - Finance product contract spec with shared state model
> - Redesigned dashboard with rituals-first UX
> - FastAPI backend with SQLite and accounts/settings APIs
> - Dashboard migrated from localStorage to backend API
>
> **Estimated Effort**: Large
> **Parallel Execution**: NO - Sequential execution required
> **Critical Path**: finance-product-contract → dashboard-ritual-ux → backend-foundation → dashboard-api-migration

---

## Context

### Original Request
Implement 4 changes sequentially for the finance dashboard:
1. finance-product-contract (new)
2. dashboard-ritual-ux
3. backend-foundation
4. dashboard-api-migration

### Interview Summary
Current state analysis:
- Existing changes: backend-foundation, dashboard-ritual-ux, dashboard-api-migration, salary-events-snapshots, telegram-finance-assistant, tbank-account-sync, deployment-readiness, deferred-ocr-photo-flow
- Current dashboard: Single-file React app with localStorage persistence
- Need to add finance-product-contract change first to establish product model

**Key Discussions**:
- Sequential execution is required: each change must complete and be archived before next starts
- Verification steps include: tasks.md verification, openspec status check, handoff/exit criteria validation
- If implementation changes contracts, update next spec before proceeding
- Archive only after verifying dependencies are properly documented

**Research Findings**:
- Dashboard uses React 18, Babel JSX, Tailwind CSS, localStorage (key: fin-v3)
- 4 existing changes with complete tasks.md files ready for implementation
- Openspec structure: changes/, specs/, archive/ directories

### Metis Review
**Identified Gaps** (addressed):
- [Missing finance-product-contract]: Created as first change to establish product foundation
- [Dependency chain]: Clearly defined sequential ordering
- [Verification protocol]: Detailed verification steps between each change

---

## Work Objectives

### Core Objective
Implement a complete finance dashboard with product contract, modern UX, backend API, and API integration following strict sequential workflow.

### Concrete Deliverables
- `openspec/changes/finance-product-contract/` - Product contract spec
- Updated `index.html` - Redesigned dashboard with rituals-first UX
- `backend/` directory - FastAPI backend with SQLite, accounts/settings APIs
- Updated `index.html` - Dashboard using backend API instead of localStorage

### Definition of Done
- [ ] All 4 changes implemented sequentially
- [ ] Each change verified and archived before next starts
- [ ] All verification steps completed for each change
- [ ] All handoff/exit criteria met

### Must Have
- Product contract defines shared state, rituals, roles
- UX redesign preserves all existing calculations
- Backend API works independently of dashboard
- Dashboard migration maintains behavioral parity
- Sequential execution: apply → verify → archive

### Must NOT Have (Guardrails)
- Starting next change before previous is archived
- Skipping verification steps between changes
- Breaking existing salary/capital calculations
- Losing localStorage data during migration
- Implementing features outside scope (OCR, historical import, etc.)

---

## Verification Strategy (MANDATORY)

> **ZERO HUMAN INTERVENTION** - ALL verification is agent-executed. No exceptions.
> Acceptance criteria requiring "user manually tests/confirms" are FORBIDDEN.

### Test Decision
- **Infrastructure exists**: NO
- **Automated tests**: NO (manual verification only)
- **Framework**: None
- **Verification**: Manual checklist + openspec status command

### QA Policy
Every change MUST follow verification protocol:
- Run all tasks from tasks.md
- Run `openspec status --change "<name>"` after implementation
- Verify entry/exit criteria met
- Check handoff dependencies satisfied
- Archive only after all checks pass

---

## Execution Strategy

> **Sequential execution** - Each change must complete before next starts.
> No parallel execution allowed due to strict dependency chain.

```
Sequential Execution:
├── Change 1: finance-product-contract (NEW - create first)
│   ├── Create product contract spec
│   ├── Define shared state model, rituals, roles
│   ├── Verify no contradictions with UX/backend specs
│   └── Archive (after all checks pass)
│
├── Change 2: dashboard-ritual-ux
│   ├── Apply UX redesign (themes, navigation, rituals-first screen)
│   ├── Verify: desktop/mobile layout, calculations preserved
│   ├── Run openspec status
│   ├── Archive (after all checks pass)
│   └── Next change depends on stable UI
│
├── Change 3: backend-foundation
│   ├── Implement FastAPI backend, SQLite, seed, API endpoints
│   ├── Verify: backend starts, seed idempotent, API works
│   ├── Run openspec status
│   ├── Archive (after all checks pass)
│   └── Next change depends on working API
│
└── Change 4: dashboard-api-migration
    ├── Migrate dashboard from localStorage to backend API
    ├── Verify: calculations match, API errors handled, race conditions avoided
    ├── Run openspec status
    ├── Archive (after all checks pass)
    └── Implementation complete

Critical Path: 1 → 2 → 3 → 4
Parallel Speedup: N/A (sequential execution only)
```

### Dependency Matrix

- **Change 1**: None - first change
- **Change 2**: Change 1 - needs product contract
- **Change 3**: Change 1 - needs product terms
- **Change 4**: Change 3 - needs backend API

### Agent Dispatch Summary

- **Change 1**: **1 agent** - quick (create spec)
- **Change 2**: **1 agent** - visual-engineering (UX redesign)
- **Change 3**: **1 agent** - unspecified-high/backend-developer (backend implementation)
- **Change 4**: **1 agent** - unspecified-high (API migration)

---

## TODOs

---

## Change 1: finance-product-contract [NEW CHANGE]

- [ ] 1. Create product contract structure

  **What to do**:
  - Create `openspec/changes/finance-product-contract/` directory
  - Create `proposal.md` with product vision and scope
  - Create `design.md` with shared state model, rituals, roles definitions
  - Create `tasks.md` with verification checklist
  - Create `.openspec.yaml` with change metadata
  - Create `specs/` directory for linked specs

  **Must NOT do**:
  - Implement any code - this is a design-only change
  - Define backend or UX-specific details (those belong in their changes)
  - Include OCR, historical import, or future features

  **Recommended Agent Profile**:
  > Select category + skills based on task domain. Justify each choice.
  - **Category**: `writing`
    - Reason: Creating documentation and spec files
  - **Skills**: [`brainstorming`]
    - `brainstorming`: Exploring product concepts before documenting

  **Parallelization**:
  - **Can Run In Parallel**: YES | NO
  - **Parallel Group**: Sequential | First change, no dependencies
  - **Blocks**: Change 2 (dashboard-ritual-ux), Change 3 (backend-foundation)
  - **Blocked By**: None - start immediately

  **References** (CRITICAL - Be Exhaustive):

  > The executor has NO context from your interview. References are their ONLY guide.
  > Each reference must answer: "What should I look at and WHY?"

  **Pattern References** (existing changes to follow):
  - `openspec/changes/backend-foundation/proposal.md` - Proposal format and structure
  - `openspec/changes/backend-foundation/design.md` - Design document format
  - `openspec/changes/backend-foundation/tasks.md` - Task format and verification checklist

  **External References** (concept patterns and frameworks):
  - No external docs needed - this is internal product modeling

  **WHY Each Reference Matters**:
  - `backend-foundation`: Shows established format for proposal/design/tasks files
  - Consistent format enables easier review and execution

  **Acceptance Criteria**:

  > **AGENT-EXECUTABLE VERIFICATION ONLY** - No human action permitted.
  > Every criterion MUST be verifiable by running a command or using a tool.

  - [ ] Directory exists: test -d openspec/changes/finance-product-contract
  - [ ] proposal.md created and valid: test -f openspec/changes/finance-product-contract/proposal.md
  - [ ] design.md created and valid: test -f openspec/changes/finance-product-contract/design.md
  - [ ] tasks.md created and valid: test -f openspec/changes/finance-product-contract/tasks.md
  - [ ] .openspec.yaml created and valid: test -f openspec/changes/finance-product-contract/.openspec.yaml
  - [ ] specs directory created: test -d openspec/changes/finance-product-contract/specs

  **QA Scenarios (MANDATORY - task is INCOMPLETE without these):**

  > **This is NOT optional. A task without QA scenarios WILL BE REJECTED.**

  ```
  Scenario: Product contract files created with proper structure
    Tool: Bash (test command)
    Preconditions: Changes directory exists
    Steps:
      1. Check finance-product-contract directory exists
      2. Verify all required files present
      3. Check .openspec.yaml has change_id and title
    Expected Result: All files exist with valid structure
    Failure Indicators: Missing files, invalid .openspec.yaml format
    Evidence: .sisyphus/evidence/change-1-files-created.log

  Scenario: Product contract defines shared state model
    Tool: Bash (grep and read)
    Preconditions: finance-product-contract/change created
    Steps:
      1. Read design.md
      2. Verify shared state section exists
      3. Check rituals definition present
      4. Check roles (dashboard/bot) defined
    Expected Result: Design document contains all required product concepts
    Failure Indicators: Missing shared state, rituals, or roles definitions
    Evidence: .sisyphus/evidence/change-1-product-concepts.log
  ```

  **Evidence to Capture**:
  - [ ] Change 1 file structure evidence
  - [ ] Product contract concepts validated

  **Commit**: NO | YES (groups with N)
  - Message: `docs: create finance-product-contract change`

- [ ] 2. Define shared state model

  **What to do**:
  - In `design.md`, define shared state: accounts, settings, salary inputs, capital calculations
  - Define state transformation rules (salary → distribution → capital)
  - Define single-user boundary and access restrictions
  - Document state persistence approach (localStorage → backend API)

  **Must NOT do**:
  - Define API endpoints or UI components (those belong in backend/UX changes)
  - Include multi-user or authorization details

  **Recommended Agent Profile**:
  - **Category**: `writing`
  - **Skills**: [`brainstorming`]

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential
  - **Blocks**: Change 2, Change 3
  - **Blocked By**: Task 1

  **References**:
  - `index.html:40-120` - Current state model (INIT_CATS, INIT_DEDS, INIT_ACCS)
  - `index.html:fmt/parse` - State transformation functions

  **Acceptance Criteria**:
  - [ ] design.md contains shared state model section
  - [ ] State transformation rules documented
  - [ ] Single-user boundary defined

  **QA Scenarios**:
  ```
  Scenario: Shared state model complete
    Tool: Bash (grep)
    Steps:
      1. Check design.md has shared state section
      2. Verify state list includes accounts, settings, salary
      3. Check transformation rules documented
    Expected Result: Complete shared state model present
    Evidence: .sisyphus/evidence/change-2-shared-state.log
  ```

  **Commit**: NO

- [ ] 3. Define rituals

  **What to do**:
  - Define ritual concept: salary input → distribution → review action
  - Define ritual lifecycle (draft, review, complete)
  - Define ritual triggers (monthly, ad-hoc, salary event)
  - Link rituals to shared state changes

  **Must NOT do**:
  - Define specific UI steps or flows (UX change handles this)
  - Define API calls to execute rituals (backend change handles this)

  **Recommended Agent Profile**:
  - **Category**: `writing`
  - **Skills**: [`brainstorming`]

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential
  - **Blocks**: Change 2
  - **Blocked By**: Task 2

  **References** (existing dashboard ritual behavior):
  - `index.html` - Current salary input and distribution form

  **Acceptance Criteria**:
  - [ ] Ritual concept defined in design.md
  - [ ] Ritual lifecycle documented
  - [ ] Ritual triggers enumerated

  **QA Scenarios**:
  ```
  Scenario: Ritual definitions complete
    Tool: Bash (grep)
    Steps:
      1. Check design.md has rituals section
      2. Verify lifecycle documented
      3. Check triggers listed
    Expected Result: Complete ritual definition present
    Evidence: .sisyphus/evidence/change-3-rituals.log
  ```

  **Commit**: NO

- [ ] 4. Define roles and responsibilities

  **What to do**:
  - Define dashboard role: UI for rituals, capital view, settings
  - Define bot role: summaries, updates, snapshots (future)
  - Define role boundaries (what each can/cannot do)
  - Document role interaction patterns

  **Must NOT do**:
  - Define specific bot commands (that's telegram-finance-assistant change)
  - Define specific UI components (that's dashboard-ritual-ux change)

  **Recommended Agent Profile**:
  - **Category**: `writing`
  - **Skills**: [`brainstorming`]

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential
  - **Blocks**: Change 2, Change 7
  - **Blocked By**: Task 3

  **Acceptance Criteria**:
  - [ ] Roles defined in design.md
  - [ ] Role boundaries documented
  - [ ] Role interactions described

  **QA Scenarios**:
  ```
  Scenario: Roles defined with boundaries
    Tool: Bash (grep)
    Steps:
      1. Check design.md has roles section
      2. Verify dashboard role defined
      3. Verify bot role defined
      4. Check boundaries documented
    Expected Result: Roles and boundaries complete
    Evidence: .sisyphus/evidence/change-4-roles.log
  ```

  **Commit**: NO

- [ ] 5. Create verification tasks

  **What to do**:
  - In `tasks.md`, create verification checklist
  - Include entry criteria: design complete, no contradictions
  - Include exit criteria: contracts in place, ready for UX/backend specs
  - Add verification step: check UX/backend specs don't override product model
  - Add verification step: run openspec status

  **Must NOT do**:
  - Include implementation tasks (this is a design-only change)

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential
  - **Blocks**: Change 2
  - **Blocked By**: Task 4

  **References**:
  - Pattern references: `openspec/changes/backend-foundation/tasks.md`

  **Acceptance Criteria**:
  - [ ] tasks.md created with verification checklist
  - [ ] Entry criteria defined
  - [ ] Exit criteria defined
  - [ ] openspec status command included

  **QA Scenarios**:
  ```
  Scenario: Verification tasks complete
    Tool: Bash (cat)
    Steps:
      1. Read tasks.md
      2. Verify entry criteria present
      3. Verify exit criteria present
      4. Check openspec status command included
    Expected Result: Complete verification checklist
    Evidence: .sisyphus/evidence/change-5-verification.log
  ```

  **Commit**: YES (with Task 1)

- [ ] 6. Complete verification

  **What to do**:
  - Run all verification tasks from tasks.md
  - Check UX specs (dashboard-ritual-ux) don't override product model
  - Check backend specs (backend-foundation) don't contradict shared state
  - Run `openspec status --change "finance-product-contract"`

  **Must NOT do**:
  - Proceed to Change 2 before verification passes

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential
  - **Blocks**: None
  - **Blocked By**: Task 5

  **Acceptance Criteria**:
  - [ ] All tasks.md verification steps passed
  - [ ] UX specs checked for conflicts
  - [ ] Backend specs checked for conflicts
  - [ ] openspec status shows no issues

  **QA Scenarios**:
  ```
  Scenario: All verification steps pass
    Tool: Bash (openspec status, grep)
    Steps:
      1. Check tasks.md items marked as complete
      2. Search UX specs for conflicts
      3. Search backend specs for conflicts
      4. Run openspec status
    Expected Result: All checks pass, no conflicts found
    Evidence: .sisyphus/evidence/change-6-final-verification.log

  Scenario: No spec conflicts found
    Tool: Bash (grep)
    Preconditions: UX and backend specs exist
    Steps:
      1. Read dashboard-ritual-ux design.md
      2. Read backend-foundation design.md
      3. Compare for contradictions with finance-product-contract
    Expected Result: No contradictions found
    Failure Indicators: Conflicting definitions detected
    Evidence: .sisyphus/evidence/change-6-conflict-check.log
  ```

  **Commit**: NO

- [ ] 7. Archive change

  **What to do**:
  - Move `openspec/changes/finance-product-contract/` to `openspec/changes/archive/finance-product-contract/`
  - Verify archive directory created
  - Confirm handoff to Change 2 complete

  **Must NOT do**:
  - Delete change instead of archiving
  - Archive before verification is complete

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential
  - **Blocks**: Change 2 start
  - **Blocked By**: Task 6

  **Acceptance Criteria**:
  - [ ] Change moved to archive: test -d openspec/changes/archive/finance-product-contract
  - [ ] Original changes directory cleaned: test ! -d openspec/changes/finance-product-contract
  - [ ] Archive contains all files

  **QA Scenarios**:
  ```
  Scenario: Change archived successfully
    Tool: Bash (test, ls)
    Steps:
      1. Verify archive directory exists
      2. Verify all files present in archive
      3. Verify original directory removed
    Expected Result: Change archived completely
    Evidence: .sisyphus/evidence/change-7-archive.log
  ```

  **Commit**: YES
  - Message: `docs: archive finance-product-contract (complete)`
  - Files: entire change directory moved

---

## Change 2: dashboard-ritual-ux

- [ ] 8. Theme foundation

  **What to do**:
  - Define theme tokens: Swiss Finance, Dark Finance, System
  - Replace mono font with sans-first, add tabular numerals
  - Persist theme preference (separate from financial data)
  - Follow tasks.md 1.1-1.3

  **References**:
  - Product contract: Rituals and dashboard role definition
  - Current styles: `index.html:11-18` (font, colors)
  - Tasks: `openspec/changes/dashboard-ritual-ux/tasks.md:1`

  **Acceptance Criteria**:
  - [ ] Theme tokens defined
  - [ ] Font system updated (sans-first, tabular numerals)
  - [ ] Theme persists in localStorage (separate key)

  **QA Scenarios**:
  ```
  Scenario: Theme tokens work across app
    Tool: Playwright
    Steps:
      1. Open index.html
      2. Switch between each theme
      3. Verify styles apply globally
      4. Refresh and verify theme persists
    Expected Result: All themes work, preference saved
    Evidence: .sisyphus/evidence/change-8-themes.png

  Scenario: Tabular numerals align properly
    Tool: Playwright
    Steps:
      1. Open index.html with Swiss Finance theme
      2. Find capital totals display
      3. Verify numbers align in columns
    Expected Result: Numbers vertically aligned
    Evidence: .sisyphus/evidence/change-8-tabular.png
  ```

  **Commit**: NO

- [ ] 9. Navigation and screens

  **What to do**:
  - Add navigation for Ритуалы, Капитал, История, Настройки
  - Make Ритуалы default first screen
  - Create history/settings shells with empty states
  - Follow tasks.md 2.1-2.3

  **References**:
  - Product contract: Dashboard role definition
  - Tasks: `openspec/changes/dashboard-ritual-ux/tasks.md:2`

  **Acceptance Criteria**:
  - [ ] Navigation component created
  - [ ] Ритуалы default screen
  - [ ] History and settings shells exist

  **QA Scenarios**:
  ```
  Scenario: Navigation works on desktop
    Tool: Playwright
    Steps:
      1. Open index.html
      2. Click each navigation item
      3. Verify screen changes
      4. Verify active state highlighted
    Expected Result: All navigation items work
    Evidence: .sisyphus/evidence/change-9-nav-desktop.png

  Scenario: Navigation works on mobile
    Tool: Playwright
    Steps:
      1. Open index.html at mobile viewport (375px)
      2. Verify no horizontal scroll
      3. Tap each navigation item
      4. Verify screens switch
    Expected Result: Mobile navigation works without overflow
    Evidence: .sisyphus/evidence/change-9-nav-mobile.png

  Scenario: History and settings have empty states
    Tool: Playwright
    Steps:
      1. Open index.html
      2. Navigate to История (History)
      3. Verify empty state message displayed
      4. Navigate to Настройки (Settings)
      5. Verify empty state or defaults shown
    Expected Result: Honest empty states shown
    Evidence: .sisyphus/evidence/change-9-shells.png
  ```

  **Commit**: NO

- [ ] 10. Ritual workspace

  **What to do**:
  - Recompose salary inputs, deductions, net salary, distribution into one workspace
  - Add compact capital strip from current totals
  - Keep finish actions visible, backend actions as placeholders
  - Follow tasks.md 3.1-3.3
  - Preserve all calculations from current dashboard

  **References**:
  - Product contract: Ritual definition
  - Current dashboard: `index.html` - salary form and capital calculations
  - Tasks: `openspec/changes/dashboard-ritual-ux/tasks.md:3`

  **Acceptance Criteria**:
  - [ ] Ritual workspace UI created
  - [ ] Capital strip shows current totals
  - [ ] Backend-dependent actions have placeholders
  - [ ] Calculations match old dashboard

  **QA Scenarios**:
  ```
  Scenario: Salary calculations preserved
    Tool: Playwright + manual verification
    Steps:
      1. Open old index.html version (copy before changes)
      2. Enter test salary: 100000
      3. Enter deductions: 10000
      4. Note net salary and distribution amounts
      5. Open redesigned index.html
      6. Enter same values
      7. Compare calculations
    Expected Result: Calculations exactly match old version
    Failure Indicators: Any discrepancy in calculations
    Evidence: .sisyphus/evidence/change-10-calculations-comparison.json

  Scenario: Capital totals match
    Tool: Playwright + manual verification
    Steps:
      1. Open old index.html
      2. Enter account balances (add test values)
      3. Note RUB and USD totals
      4. Open redesigned index.html
      5. Enter same balances
      6. Compare totals
    Expected Result: Totals match within floating-point tolerance
    Failure Indicators: Discrepancy in totals
    Evidence: .sisyphus/evidence/change-10-capital-comparison.json

  Scenario: Workspace layout on desktop
    Tool: Playwright
    Steps:
      1. Open index.html
      2. Verify desktop has two-column layout
      3. Verify salary inputs visible
      4. Verify distribution visible
      5. Verify capital strip visible
    Expected Result: All workspace elements visible and organized
    Evidence: .sisyphus/evidence/change-10-workspace-desktop.png

  Scenario: Workspace layout on mobile
    Tool: Playwright
    Steps:
      1. Open index.html at 375px viewport
      2. Verify no horizontal scroll
      3. Verify elements stacked vertically
      4. Verify all elements visible without overflow
    Expected Result: Mobile layout works without scroll
    Evidence: .sisyphus/evidence/change-10-workspace-mobile.png

  Scenario: Backend actions have placeholders
    Tool: Playwright
    Steps:
      1. Open ritual workspace
      2. Look for backend-dependent actions (save snapshot, etc.)
      3. Verify they show unavailable/disabled state
      4. Verify placeholder text explains why unavailable
    Expected Result: Backend actions honestly unavailable
    Evidence: .sisyphus/evidence/change-10-placeholders.png
  ```

  **Commit**: YES (with Tasks 8-10)

- [ ] 11. Run verification

  **What to do**:
  - Run all tasks.md verification (4.1-4.4)
  - Verify desktop layout (4.1)
  - Verify mobile layout (4.2)
  - Verify calculations preserved (4.3)
  - Run openspec status (4.4)

  **References**:
  - `openspec/changes/dashboard-ritual-ux/tasks.md:4`

  **Acceptance Criteria**:
  - [ ] Desktop layout two columns verified
  - [ ] Mobile layout no horizontal scroll verified
  - [ ] Calculations match pre-redesign dashboard
  - [ ] openspec status shows no issues

  **QA Scenarios**:
  ```
  Scenario: Desktop layout verified
    Tool: Playwright
    Steps:
      1. Open index.html at desktop viewport (1920px)
      2. Verify two-column layout present
      3. Verify navigation on left, content on right
      4. Screenshot layout
    Expected Result: Desktop layout has two columns
    Evidence: .sisyphus/evidence/change-11-desktop-layout.png

  Scenario: Mobile layout verified
    Tool: Playwright
    Steps:
      1. Open index.html at 375px viewport
      2. Try to scroll horizontally
      3. Verify no content cut off
      4. Verify all elements accessible
    Expected Result: No horizontal scroll possible
    Evidence: .sisyphus/evidence/change-11-mobile-layout.png

  Scenario: openspec status clean
    Tool: Bash
    Steps:
      1. Run openspec status --change "dashboard-ritual-ux"
      2. Check output for errors
      3. Verify change shows active or complete state
    Expected Result: Clean status output
    Evidence: .sisyphus/evidence/change-11-openspec-status.log
  ```

  **Commit**: NO

- [ ] 12. Archive change

  **What to do**:
  - Move to `openspec/changes/archive/dashboard-ritual-ux/`
  - Verify clean archive
  - Confirm handoff to Change 3

  **Acceptance Criteria**:
  - [ ] Change archived
  - [ ] All files present in archive

  **QA Scenarios**:
  ```
  Scenario: Change archived successfully
    Tool: Bash
    Steps:
      1. Verify archive directory exists
      2. Verify all files archived
      3. Verify original removed
    Expected Result: Clean archive
    Evidence: .sisyphus/evidence/change-12-archive.log
  ```

  **Commit**: YES
  - Message: `docs: archive dashboard-ritual-ux (complete)`

---

## Change 3: backend-foundation

- [ ] 13. Configuration setup

  **What to do**:
  - Create backend/ directory structure
  - Add typed settings (DATABASE_URL, ALLOWED_ORIGINS, etc.)
  - Add .env.example and ensure .env secrets ignored
  - Document local defaults and deployment overrides
  - Follow tasks.md 1.1-1.3

  **References**:
  - Product contract: Single-user boundary
  - External docs: FastAPI settings, SQLAlchemy configuration
  - Tasks: `openspec/changes/backend-foundation/tasks.md:1`

  **Acceptance Criteria**:
  - [ ] backend/ directory structure created
  - [ ] Settings module with typed configuration
  - [ ] .env.example present
  - [ ] Django-style .env in .gitignore

  **QA Scenarios**:
  ```
  Scenario: Backend structure created
    Tool: Bash
    Steps:
      1. Verify backend/ directory exists
      2. Check __init__.py, main.py, config.py, models.py
      3. Verify FastAPI dependency in requirements.txt or equivalent
    Expected Result: Backend structure complete
    Evidence: .sisyphus/evidence/change-13-structure.log

  Scenario: .env.example present
    Tool: Bash
    Steps:
      1. Verify .env.example exists
      2. Verify DATABASE_URL, ALLOWED_ORIGINS documented
      3. Verify .gitignore has .env entry
    Expected Result: Env template ready
    Evidence: .sisyphus/evidence/change-13-env.log
  ```

  **Commit**: NO

- [ ] 14. Database and seed

  **What to do**:
  - Add SQLAlchemy engine/session/base
  - Create Account and Settings models
  - Add idempotent seed from current defaults
  - Follow tasks.md 2.1-2.3

  **References**:
  - Product contract: Shared state model (accounts, settings)
  - Current defaults: `index.html:55-100` (INIT_CATS, INIT_DEDS, INIT_ACCS)
  - External docs: SQLAlchemy models, seed patterns
  - Tasks: `openspec/changes/backend-foundation/tasks.md:2`

  **Acceptance Criteria**:
  - [ ] SQLAlchemy models created
  - [ ] Database schema migration ready
  - [ ] Seed script idempotent (safe to run twice)

  **QA Scenarios**:
  ```
  Scenario: Database models created
    Tool: Bash
    Steps:
      1. Verify models.py exists
      2. Check Account class with required fields
      3. Check Settings class with required fields
      4. Verify foreign keys correct
    Expected Result: Models match shared state contract
    Evidence: .sisyphus/evidence/change-14-models.log

  Scenario: Seed is idempotent
    Tool: Bash
    Steps:
      1. Run seed script first time
      2. Record database row counts
      3. Run seed script second time
      4. Compare row counts (should be same)
    Expected Result: Seed safe to run twice
    Failure Indicators: Duplicate rows created
    Evidence: .sisyphus/evidence/change-14-seed-idempotent.log
  ```

  **Commit**: NO

- [ ] 15. API and serving

  **What to do**:
  - Add GET /api/accounts (read-only, narrow update)
  - Add GET /api/settings (read-only, partial update)
  - Serve static dashboard from FastAPI
  - Configure CORS for local and deployed origins
  - Follow tasks.md 3.1-3.4

  **References**:
  - Product contract: Single-user boundary, dashboard role
  - External docs: FastAPI static files, CORS middleware
  - Tasks: `openspec/changes/backend-foundation/tasks.md:3`

  **Acceptance Criteria**:
  - [ ] /api/accounts endpoint exists
  - [ ] /api/settings endpoint exists
  - [ ] Dashboard served at /index.html
  - [ ] CORS configured for localhost and deployed URL

  **QA Scenarios**:
  ```
  Scenario: Backend starts with defaults
    Tool: Bash (curl)
    Steps:
      1. Start backend server (uvicorn backend.main:app)
      2. Wait for startup (sleep 3)
      3. Check health endpoint or root path
      4. Verify server responds
    Expected Result: Backend starts successfully
    Evidence: .sisyphus/evidence/change-15-backend-start.log

  Scenario: Accounts API works
    Tool: Bash (curl)
    Preconditions: Backend running
    Steps:
      1. curl http://localhost:8000/api/accounts
      2. Verify JSON response
      3. Verify all seeded accounts present
      4. Verify response status 200
    Expected Result: Accounts API returns correct data
    Evidence: .sisyphus/evidence/change-15-accounts-api.json

  Scenario: Settings API works
    Tool: Bash (curl)
    Preconditions: Backend running
    Steps:
      1. curl http://localhost:8000/api/settings
      2. Verify JSON response
      3. Verify settings present
      4. Verify response status 200
    Expected Result: Settings API returns correct data
    Evidence: .sisyphus/evidence/change-15-settings-api.json

  Scenario: Static dashboard served
    Tool: Bash (curl)
    Preconditions: Backend running
    Steps:
      1. curl http://localhost:8000/index.html
      2. Verify HTML response
      3. Verify React app loads
      4. Verify response status 200
    Expected Result: Dashboard HTML served
    Evidence: .sisyphus/evidence/change-15-static-serve.html

  Scenario: CORS configured
    Tool: Bash (curl with headers)
    Preconditions: Backend running
    Steps:
      1. curl -H "Origin: http://localhost:3000" http://localhost:8000/api/accounts -i
      2. Check Access-Control-Allow-Origin header
      3. Verify includes localhost origin
    Expected Result: CORS headers present
    Evidence: .sisyphus/evidence/change-15-cors.log
  ```

  **Commit**: YES (with Tasks 13-15)

- [ ] 16. Run verification

  **What to do**:
  - Run all tasks.md verification (4.1-4.4)
  - Verify backend starts (4.1)
  - Verify seed idempotent (already done in 14)
  - Verify API status/error behavior (4.3)
  - Run openspec status (4.4)

  **References**:
  - `openspec/changes/backend-foundation/tasks.md:4`

  **Acceptance Criteria**:
  - [ ] Backend starts with local defaults
  - [ ] Seed safe to run twice
  - [ ] API status and error behavior correct
  - [ ] openspec status shows no issues

  **QA Scenarios**:
  ```
  Scenario: API error behavior
    Tool: Bash (curl)
    Preconditions: Backend running
    Steps:
      1. curl http://localhost:8000/api/nonexistent
      2. Verify response status 404
      3. Verify JSON error message
      4. Verify no stack trace in response
    Expected Result: Proper error response
    Evidence: .sisyphus/evidence/change-16-api-errors.json

  Scenario: openspec status clean
    Tool: Bash
    Steps:
      1. Run openspec status --change "backend-foundation"
      2. Check for errors
      3. Verify clean status
    Expected Result: Clean status output
    Evidence: .sisyphus/evidence/change-16-openspec-status.log
  ```

  **Commit**: NO

- [ ] 17. Archive change

  **What to do**:
  - Move to `openspec/changes/archive/backend-foundation/`
  - Verify clean archive
  - Confirm handoff to Change 4

  **Acceptance Criteria**:
  - [ ] Change archived
  - [ ] All files present

  **QA Scenarios**:
  ```
  Scenario: Change archived successfully
    Tool: Bash
    Steps:
      1. Verify archive directory
      2. Verify files archived
      3. Verify original removed
    Expected Result: Clean archive
    Evidence: .sisyphus/evidence/change-17-archive.log
  ```

  **Commit**: YES
  - Message: `feat: add backend-foundation (complete)`

---

## Change 4: dashboard-api-migration

- [ ] 18. Initial read and import

  **What to do**:
  - Load accounts and settings from backend on startup
  - Detect existing fin-v3 localStorage data
  - Offer import path if backend empty
  - Don't invent salary history from non-persisted inputs
  - Follow tasks.md 1.1-1.3

  **References**:
  - Product contract: Shared state, single-user boundary
  - Previous state: localStorage key "fin-v3"
  - Tasks: `openspec/changes/dashboard-api-migration/tasks.md:1`

  **Acceptance Criteria**:
  - [ ] Dashboard loads from backend API on startup
  - [ ] localStorage data detected and offered for import
  - [ ] No fake salary history created

  **QA Scenarios**:
  ```
  Scenario: Dashboard loads from backend
    Tool: Playwright
    Preconditions: Backend running with seeded data
    Steps:
      1. Open http://localhost:8000/index.html
      2. Wait for React to load
      3. Check accounts display (should show backend data)
      4. Check settings display (should show backend settings)
    Expected Result: Dashboard shows backend data
    Evidence: .sisyphus/evidence/change-18-load-backend.png

  Scenario: Import localStorage data offered
    Tool: Playwright + localStorage manipulation
    Preconditions: Backend running with no data, localStorage has fin-v3
    Steps:
      1. Clear backend database (if needed)
      2. Set localStorage fin-v3 with test data
      3. Open http://localhost:8000/index.html
      4. Verify import prompt shown
      5. Click import and verify data appears
    Expected Result: Import prompt appears, data migrates
    Evidence: .sisyphus/evidence/change-18-import-flow.png

  Scenario: No fake salary history
    Tool: Playwright
    Preconditions: Fresh backend, no history
    Steps:
      1. Open index.html
      2. Complete ritual with salary inputs
      3. Navigate to history (should be empty)
      4. Verify no salary events created from inputs
    Expected Result: History remains empty without explicit save
    Evidence: .sisyphus/evidence/change-18-no-fake-history.png
  ```

  **Commit**: NO

- [ ] 19. API writes

  **What to do**:
  - Replace localStorage settings persistence with partial API updates
  - Replace account balance persistence with API updates
  - Prevent stale whole-array writes
  - Follow tasks.md 2.1-2.3

  **References**:
  - Previous dashboard: localStorage.setItem usage
  - Tasks: `openspec/changes/dashboard-api-migration/tasks.md:2`

  **Acceptance Criteria**:
  - [ ] Settings saved via API (PATCH /api/settings)
  - [ ] Account balances saved via API (PATCH /api/accounts/:id)
  - [ ] Stale writes blocked

  **QA Scenarios**:
  ```
  Scenario: Settings saved via API
    Tool: Playwright + backend logs
    Preconditions: Backend running
    Steps:
      1. Open index.html
      2. Change a setting value
      3. Verify loading indicator shows save-pending
      4. Wait for API response
      5. Verify success state
      6. Check backend logs for PATCH /api/settings
    Expected Result: Settings saved via API
    Evidence: .sisyphus/evidence/change-19-settings-api-write.log

  Scenario: Account balances saved via API
    Tool: Playwright + backend logs
    Preconditions: Backend running
    Steps:
      1. Open index.html
      2. Change account balance
      3. Verify save-pending state
      4. Wait for response
      5. Check backend logs for PATCH /api/accounts/:id
    Expected Result: Balance saved via API
    Evidence: .sisyphus/evidence/change-19-accounts-api-write.log

  Scenario: Stale writes blocked
    Tool: Playwright + manual latency
    Preconditions: Backend running
    Steps:
      1. Open index.html
      2. Change account balance, but delay network (throttle network)
      3. Change same account balance again while first save pending
      4. Verify first save cancelled or marked stale
      5. Verify second save completes
      6. Check backend has only latest value
    Expected Result: Stale writes blocked
    Evidence: .sisyphus/evidence/change-19-stale-write-blocked.log
  ```

  **Commit**: NO

- [ ] 20. States and error handling

  **What to do**:
  - Add loading, save-pending, save-failed, retry states
  - Check response.ok and surface errors
  - Ignore/cancel stale fetch responses
  - Follow tasks.md 3.1-3.3

  **References**:
  - Previous dashboard: No error states (localStorage always succeeds)
  - Tasks: `openspec/changes/dashboard-api-migration/tasks.md:3`

  **Acceptance Criteria**:
  - [ ] Loading state shown on initial fetch
  - [ ] Save-pending state shown while API request in flight
  - [ ] Save-failed state shown on API error
  - [ ] Retry enabled after failed save
  - [ ] Stale responses ignored

  **QA Scenarios**:
  ```
  Scenario: Loading state shown
    Tool: Playwright
    Preconditions: Backend running
    Steps:
      1. Clear localStorage
      2. Open index.html
      3. Verify loading indicator shows
      4. Wait for data load
      5. Verify loading indicator gone
    Expected Result: Loading state visible during fetch
    Evidence: .sisyphus/evidence/change-20-loading-state.png

  Scenario: Save-pending state shown
    Tool: Playwright
    Preconditions: Backend running
    Steps:
      1. Open index.html
      2. Change setting value
      3. Verify save-pending indicator shown (spinner, etc.)
      4. Wait for success
      5. Verify indicator gone
    Expected Result: Save-pending state visible
    Evidence: .sisyphus/evidence/change-20-pending-state.png

  Scenario: Save-failed state shown
    Tool: Playwright + failure simulation
    Preconditions: Backend running
    Steps:
      1. Stop backend server (simulate network error)
      2. Change setting value
      3. Verify save-failed state shown with error message
      4. Verify retry button or action available
    Expected Result: Save-failed state with error displayed
    Evidence: .sisyphus/evidence/change-20-failed-state.png

  Scenario: API errors surfaced
    Tool: Playwright + backend logs
    Preconditions: Backend running
    Steps:
      1. Modify backend to return 500 error for settings
      2. Change setting in dashboard
      3. Verify error message shows (not generic)
    Expected Result: Specific error message from API response
    Evidence: .sisyphus/evidence/change-20-api-errors.log

  Scenario: Stale responses ignored
    Tool: Playwright + manual response ordering
    Preconditions: Backend running
    Steps:
      1. Change setting, delay first response
      2. Change same setting again, expedite second response
      3. Verify second response wins
      4. Verify first ignored
    Expected Result: Latest response always applied
    Evidence: .sisyphus/evidence/change-20-stale-response.log
  ```

  **Commit**: YES (with Tasks 18-20)

- [ ] 21. Run verification

  **What to do**:
  - Run all tasks.md verification (4.1-4.4)
  - Verify salary calculations match localStorage version
  - Verify capital totals match localStorage version
  - Verify failed API writes not shown as saved
  - Run openspec status

  **References**:
  - `openspec/changes/dashboard-api-migration/tasks.md:4`

  **Acceptance Criteria**:
  - [ ] Salary calculations match localStorage version
  - [ ] Capital totals match localStorage version
  - [ ] Failed saves show error, not success
  - [ ] openspec status clean

  **QA Scenarios**:
  ```
  Scenario: Salary calculations match
    Tool: Playwright + comparison
    Preconditions: Both backend and localStorage versions available
    Steps:
      1. Clone index.html to index-local.html (localStorage version)
      2. Open both in tabs
      3. Enter same salary input in both
      4. Enter same deductions in both
      5. Compare net salary calculation
      6. Compare distribution amounts
    Expected Result: Calculations exactly match
    Failure Indicators: Any discrepancy
    Evidence: .sisyphus/evidence/change-21-calculations-match.json

  Scenario: Capital totals match
    Tool: Playwright + comparison
    Preconditions: Both versions available
    Steps:
      1. Open both versions
      2. Enter same account balances
      3. Compare RUB total
      4. Compare USD total
    Expected Result: Totals match within floating-point tolerance
    Failure Indicators: Discrepancy
    Evidence: .sisyphus/evidence/change-21-capital-match.json

  Scenario: Failed saves not shown as saved
    Tool: Playwright + backend failure
    Preconditions: Backend running
    Steps:
      1. Modify backend to reject updates
      2. Change account balance in dashboard
      3. Verify save-failed state shown
      4. Verify value didn't change in UI (or reverts)
      5. Verify success state not shown
    Expected Result: Failed save clearly indicated
    Evidence: .sisyphus/evidence/change-21-failed-not-saved.png

  Scenario: openspec status clean
    Tool: Bash
    Steps:
      1. Run openspec status --change "dashboard-api-migration"
      2. Check for errors
      3. Verify clean status
    Expected Result: Clean status
    Evidence: .sisyphus/evidence/change-21-openspec-status.log
  ```

  **Commit**: NO

- [ ] 22. Archive change

  **What to do**:
  - Move to `openspec/changes/archive/dashboard-api-migration/`
  - Verify clean archive
  - Implementation complete

  **Acceptance Criteria**:
  - [ ] Change archived
  - [ ] All 4 changes complete

  **QA Scenarios**:
  ```
  Scenario: Final change archived
    Tool: Bash
    Steps:
      1. Verify archive directory
      2. Verify files archived
      3. Verify original removed
      4. Count archived changes (should be 4)
    Expected Result: All changes archived
    Evidence: .sisyphus/evidence/change-22-final-archive.log
  ```

  **Commit**: YES
  - Message: `feat: complete dashboard-api-migration (all 4 changes complete)`

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.
>
> **Do NOT auto-proceed after verification. Wait for user's explicit approval before marking work complete.**
> **Never mark F1-F4 as checked before getting user's okay.** Rejection or user feedback -> fix -> re-run -> present again -> wait for okay.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, curl endpoint, run command). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in .sisyphus/evidence/. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run no build step (no package manager), but check for obvious issues: console.log in prod, empty catches, commented-out code, unused imports (check imports in index.html). Check AI slop: excessive comments, over-abstraction, generic names (data/result/item/temp).
  Output: `Lint [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high` (+ `playwright-skill`)
  Start from clean state. Execute EVERY QA scenario from EVERY task — follow exact steps, capture evidence. Test cross-task integration (features working together, not isolation). Test edge cases: empty state, invalid input, rapid actions. Save to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [N/N] | Edge Cases [N tested] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (git log/diff). Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance. Detect cross-task contamination: Task N touching Task M's files. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

- **1**: `docs: create finance-product-contract` - proposal.md, design.md, tasks.md, .openspec.yaml
- **10**: `feat: implement dashboard-ritual-ux` - index.html theme, navigation, workspace
- **15**: `feat: implement backend-foundation` - backend/ main.py, config.py, models.py
- **22**: `feat: complete dashboard-api-migration` - index.html API integration, all changes archived

---

## Success Criteria

### Verification Commands
```bash
# Check all changes archived
ls openspec/changes/archive/ | grep -E "(finance-product-contract|dashboard-ritual-ux|backend-foundation|dashboard-api-migration)"
# Expected: 4 directories

# Check no pending changes
ls openspec/changes/ | grep -v "^archive$"
# Expected: other directories only (not the 4 implemented changes)

# Backend starts
uvicorn backend.main:app
# Expected: Server running on port

# Dashboard loads from backend
curl http://localhost:8000/index.html
# Expected: HTML response

# API works
curl http://localhost:8000/api/accounts
curl http://localhost:8000/api/settings
# Expected: JSON responses with data
```

### Final Checklist
- [ ] All 4 changes archived
- [ ] Finance product contract defines shared state
- [ ] UX redesign preserves calculations
- [ ] Backend API works independently
- [ ] Dashboard migrated from localStorage
- [ ] All verification steps passed
- [ ] All QA scenarios executed
- [ ] All evidence files captured

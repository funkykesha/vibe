# Finance Dashboard Sequential Changes Implementation

## TL;DR

> **Quick Summary**: Implement 4 existing OpenSpec changes sequentially: dashboard-ritual-ux → backend-foundation → dashboard-api-migration → salary-events-snapshots. Each change follows apply → verify → archive pattern with strict handoff validation.
>
> **Deliverables**:
> - Redesigned dashboard with rituals-first UX and theme modes
> - FastAPI backend with SQLite database and accounts/settings APIs
> - Dashboard migrated from localStorage to backend API
> - Salary events and snapshots system for historical tracking
>
> **Estimated Effort**: Large
> **Parallel Execution**: NO - Sequential execution required by dependency chain
> **Critical Path**: dashboard-ritual-ux → backend-foundation → dashboard-api-migration → salary-events-snapshots

---

## Context

### Original Request
Implement 4 changes sequentially for the finance dashboard:
1. **dashboard-ritual-ux** - UI/UX redesign with rituals-first interface
2. **backend-foundation** - Backend infrastructure with SQLite and API
3. **dashboard-api-migration** - Migrate dashboard from localStorage to API
4. **salary-events-snapshots** - Salary events and snapshots for history

### Interview Summary

**Current State Analysis**:
- **Project**: Single-file React 18 dashboard (index.html) with localStorage persistence (key: fin-v3)
- **Dependencies**: Tailwind CSS via CDN, Babel for JSX transformation, no build step
- **Existing Changes**: 4 OpenSpec changes already defined with complete specs/tasks
- **Repository Structure**: openspec/changes/ directory with proposal.md, design.md, tasks.md, specs/ for each change

**Key Discussions**:
- Sequential execution is mandatory: each change must complete, be verified, archived before next begins
- Verification protocol between changes: tasks.md verification → openspec status → exit criteria → contract updates if needed → archive
- Dependency chain: UX stabilizes first → backend foundation → API migration → salary events history
- If implementation changes a contract, the next spec must be updated before proceeding
- Archive only after verifying next change doesn't depend on undocumented details

**Research Findings**:
- **Dashboard Structure**: React components for salary input, capital display, settings, all in single file
- **Data Flow**: localStorage (fin-v3) → React state → UI calculations → localStorage writes
- **Backend Requirements**: FastAPI, SQLAlchemy, SQLite, static serving, CORS configuration
- **OpenSpec CLI**: Available at `/opt/homebrew/bin/openspec` with status command for verification

**Technical Constraints**:
- No automated test infrastructure exists - verification must be manual
- Single-file React app must maintain existing calculation precision
- localStorage data must be preserved/migrated, not lost
- Backend should work independently before dashboard migration

---

## Work Objectives

### Core Objective
Implement all 4 OpenSpec changes sequentially to transform the finance dashboard from a localStorage-based app to a full-stack application with modern UX and historical tracking capabilities.

### Concrete Deliverables
- **Updated index.html** - Redesigned dashboard with rituals-first UX, theme modes, navigation
- **backend/ directory** - FastAPI backend with SQLite database, accounts/settings APIs
- **Updated index.html** - Dashboard migrated to backend API with loading/error states
- **Enhanced backend** - Salary events API, snapshots creation, comparison endpoints

### Definition of Done
- [ ] All 4 changes implemented in strict sequence
- [ ] Each change verified via tasks.md checklist and openspec status
- [ ] Entry/exit criteria validated between each change
- [ ] All changes archived sequentially after full verification
- [ ] No regression in salary/capital calculations
- [ ] Backend works independently before dashboard migration
- [ ] Complete product loop: salary → events → snapshots → history ready

### Must Have
- **dashboard-ritual-ux**: Theme modes, navigation, rituals-first screen, capital context, history/settings shells
- **backend-foundation**: SQLite database, accounts/settings APIs, static serving, CORS, seed script
- **dashboard-api-migration**: API integration, localStorage import path, loading/error states, race protection
- **salary-events-snapshots**: Salary events API, snapshots creation, comparison, history readiness
- **Calculation Preservation**: All existing salary and capital calculations remain accurate
- **Data Migration**: Existing localStorage data is migrated, not lost
- **Sequential Workflow**: apply → verify → archive for each change

### Must NOT Have (Guardrails)

**CRITICAL EXECUTION GUARDRAILS (STRICT ENFORCEMENT)**

**1. Sequential Execution Mandate:**
- NO parallel work under any circumstances
- NO starting Change N until Change N-1 is FULLY ARCHIVED
- NO skipping openspec status verification before archival
- NO ignoring warnings or errors in status output

**2. No Silent Data Loss:**
- Backend overwrites NOT allowed without explicit user confirmation
- API failures MUST be visible to user, never silent
- localStorage import MUST warn before overwriting non-empty backend data
- Settings partial updates MUST preserve unrelated fields

**3. Calculation Precision Rules:**
- Preserve exact parse/fmt function behavior (no changes)
- Use existing parse function: replaces space, comma with decimal point, handles empty/null
- Comparison tolerance: 0.01 RUB (1 kopeck) acceptable for verification
- All calculations must match baseline within tolerance

**4. Sequential State Integrity:**
- localStorage key "fin-v3" is ONLY for migration import (read-only after Change 3)
- Theme persistence uses separate key: "fin-v3-theme"
- No new localStorage keys without specifying purpose and lifetime
- Backend is persistence layer ONLY - no calculation logic in backend

**5. Empty State Truthfulness:**
- History shell: "История недоступна - требуется система снимков" (NOT "Coming soon", NOT fake charts)
- Settings shell: "Настройки недоступны - backend не подключен" (NOT "Login required")
- All disabled states show honest reasons, not generic messages
- No placeholder data that looks real

**6. Scope Lock-Down:**
- Change 1: NO settings CRUD, NO history UI, placeholder shells only
- Change 2: NO authentication, NO users table, NO production deployment SSL
- Change 3: NO auto-retry logic, NO offline mode beyond basic error handling
- Change 4: API ONLY - NO history visualization UI, NO salary events management UI

**7. Inter-Change Protocol:**
- If implementation changes next change's contract: STOP, update spec, BEFORE proceeding
- Pre-change N smoke test: Verify changes 1..N-1 still work before starting change N
- Archival verification: Change directory moved, original gone, status shows archived
- Warnings are BLOCKS: Resolve all warnings before proceeding

### Must NOT Have (Guardrails)
- Starting next change before previous is archived (STRICT)
- Skipping verification steps between changes
- Breaking existing salary/capital calculations
- Losing localStorage data during migration
- Implementing features outside defined scope (OCR, historical import, bot features)
- Creating historical salaries or data from thin air
- Silent failures during API migration
- Race conditions or stale state issues

---

## Verification Strategy (MANDATORY)

> **ZERO HUMAN INTERVENTION** - ALL verification is agent-executed. No exceptions.
> Acceptance criteria requiring "user manually tests/confirms" are FORBIDDEN.

### Test Decision
- **Infrastructure exists**: NO (no automated test suite)
- **Automated tests**: NO (manual verification via browser + openspec status)
- **Framework**: None
- **Verification**: Manual checklist execution + openspec status command

### QA Policy
Every change MUST follow strict verification protocol:

**Between Changes:**
1. Execute all tasks from tasks.md verification section
2. Run `openspec status --change "<change-name>"`
3. Verify entry criteria met before starting
4. Verify exit criteria met before proceeding
5. If implementation changed contract, update next spec first
6. Archive change only after verifying next change's dependencies satisfied

**Per-Change Verification:**
- Open browser to test UI/UX changes
- Run backend server to test API endpoints
- Test calculations against baseline
- Check localStorage behavior
- Verify error handling and edge cases
- Capture evidence to .sisyphus/evidence/

**Agent-Executed QA Scenarios:**
- **Frontend/UI**: Playwright (playwright skill) - Navigate, interact, assert DOM, screenshots
- **API/Backend**: Bash (curl) - Send requests, assert status + response fields
- **CLI/Commands**: Bash - Run commands, verify output, check exit codes

Each scenario includes exact steps, specific selectors, concrete test data, expected results, and evidence paths.

---

## Execution Strategy

> **Sequential execution** - Each change must complete before next starts.
> No parallel execution allowed due to strict dependency chain and verification protocol.

**MIGRATION RISK MITIGATION STRATEGIES:**

**Risk: Change 2 (backend) becomes critical bottleneck**
**Mitigation:** Pre-implementation spike before Change 2
- Build minimal FastAPI + SQLite + SQLAlchemy skeleton (1 day max)
- Test all tech stack assumptions work (no hidden complexity)
- Test seed script idempotence with realistic data
- Test CORS behavior with local browser
- **Decision Gate:** Only proceed to full Change 2 after spike success

**Risk: No rollback path for Change 3 (API migration)**
**Mitigation:** Fallback mode design in Change 3
- If all API requests fail for > 10 seconds: Show "Режим оффлайн - данные из кэша"
- Allow read-only access to last known good state
- Disable save actions with message: "Backend недоступен - невозможно сохранить изменения"
- This is NOT reversion to localStorage, but emergency read-only mode

**Risk: Sequential timeline unpredictability**
**Mitigation:** Timeboxing with decision gates
- Each change has maximum effort estimate (Change 1: 2 days, Change 2: 5 days, Change 3: 3 days, Change 4: 3 days)
- If estimate exceeded by 50%: STOP and reassess
- Options: Reduce scope, defer to later change, reconsider approach
- Must update plan and get user approval before continuing

```
Sequential Execution Flow:
│
├── Pre-Implementation
│   └── Capture baseline calculations from current dashboard
│
├── Change 1: dashboard-ritual-ux (Estimated: 2 days)
│   ├── Apply: Theme modes, navigation, rituals-first UX
│   ├── Verify: Layout responsive, calculations preserved vs baseline
│   ├── Check: openspec status --change "dashboard-ritual-ux"
│   ├── Validate: Exit criteria met, baseline calculations match
│   └── Archive: After all checks pass
│
├── Pre-Change 2: Spike Validation (1 day max)
│   ├── Build minimal FastAPI + SQLAlchemy skeleton
│   ├── Test SQLite integration and seed script
│   ├── Test CORS with local browser
│   └── Decision Gate: Proceed only if spike successful
│
├── Change 2: backend-foundation (Estimated: 5 days)
│   ├── Apply: FastAPI backend, SQLite, seed, APIs
│   ├── Verify: Backend starts, seed idempotent, API works independently
│   ├── Check: openspec status --change "backend-foundation"
│   ├── Validate: Exit criteria met, backend works without dashboard
│   └── Archive: After all checks pass
│
├── Change 3: dashboard-api-migration (Estimated: 3 days)
│   ├── Apply: Dashboard API integration, state management, fallback mode
│   ├── Verify: Calculations match baseline, errors handled, race avoided
│   ├── Check: openspec status --change "dashboard-api-migration"
│   ├── Validate: Exit criteria met, source-of-truth unified
│   └── Archive: After all checks pass
│
└── Change 4: salary-events-snapshots (Estimated: 3 days)
    ├── Apply: Salary events API, snapshots, comparison
    ├── Verify: Events saved, snapshots explicit, comparison works
    ├── Check: openspec status --change "salary-events-snapshots"
    ├── Validate: Exit criteria met, product loop complete
    └── Archive: Final change, implementation complete

Critical Path: Baseline → 1 → Spike → 2 → 3 → 4
Parallel Speedup: N/A (strictly sequential)
Total Estimated: 17 days (including spike)
Decision Gates: Spike before Change 2, timebox checkpoints
```

### Dependency Matrix

- **Baseline Capture**: None - starts immediately (Task -1 before Change 1)
- **Change 1 (dashboard-ritual-ux)**: Baseline Capture - needs calculations to compare
- **Change 2 (backend-foundation)**: Change 1 - needs stable UI design
- **Change 3 (dashboard-api-migration)**: Change 2 - needs working backend API
- **Change 4 (salary-events-snapshots)**: Change 3 - needs unified data source

### Inter-Change Validation Protocol (EXPANDED)

**Before starting Change N:**
1. **Smoke Test Changes 1..N-1:**
   - Start backend (if Change 2 exists) and verify it still boots
   - Open dashboard (if Change 1 exists) and verify it still renders
   - Run simple API calls to verify contract still valid (if backend exists)
   - If smoke test fails: STOP, fix regression before proceeding

2. **Verify Archival Status:**
   - Check openspec/changes/archive/ contains Change N-1
   - Verify openspec/changes/ does NOT contain Change N-1
   - Run `openspec status --change "change-n-1"` - should show archived

3. **Review Change N spec for hidden dependencies:**
   - Create dependency graph from spec text
   - Validate all dependencies are documented in previous specs
   - If undocumented dependency found: Add to spec or remove from implementation

**During Change N implementation:**
1. **If you discover a contract change affecting Change N+1:**
   - STOP implementation immediately
   - Update Change N+1 spec to reflect new contract
   - Re-validate Change N+1 entry criteria
   - Resume implementation only after spec update complete

2. **If warnings appear in openspec status:**
   - Warnings are BLOCKS - resolve all before proceeding
   - No "informational only" exception
   - Document resolution in plan/draft

**After Change N implementation:**
1. Run all verification tasks from tasks.md manually
2. Run `openspec status --change "<change-n>"`
3. Verify exit criteria met:
   - All acceptance criteria satisfied
   - All QA scenarios completed with evidence
   - Baseline calculations still match (if Change 1)
   - Backend works independently (if Change 2)
4. Check that Change N+1 dependencies are satisfied
5. Archive Change N:
   ```bash
   openspec archive "<change-n>"
   # Verify: Directory moved to archive/, original gone, status shows archived
   ```
6. Only then proceed to Change N+1

### Agent Dispatch Summary

- **Change 1**: **1 agent** - visual-engineering (UX redesign)
- **Change 2**: **1 agent** - backend-developer (FastAPI backend)
- **Change 3**: **1 agent** - fullstack-developer (API integration)
- **Change 4**: **1 agent** - backend-developer (salary events & snapshots)

No parallel execution - strict sequential workflow.

---

## TODOs

> Implementation = ONE Task. Never separate unless explicitly required by workflow.
> EVERY task MUST have: Recommended Agent Profile + QA Scenarios (MANDATORY).
> **A task WITHOUT QA Scenarios is INCOMPLETE. No exceptions.**

---

## PRE-IMPLEMENTATION: Baseline Capture (Task -1)

**Purpose**: Capture current dashboard calculations as reference point to verify no regression in Change 1.

- [ ] -1. Capture Calculation Baseline

  **What to do**:
  - Create test data set representing typical use case (salary, deductions, accounts)
  - Run current dashboard with test data
  - Capture all calculation outputs: net salary, distribution amounts, capital totals, USD values
  - Save baseline to `.sisyphus/baseline/calculations.json`
  - Verify baseline is reproducible (run twice, identical results)

  **Must NOT do**:
  - Modify any code before baseline captured
  - Use trivial edge case data only - needs representative realistic inputs

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Manual testing and data capture, mixed tasks
  - **Skills**: [`playwright-skill`]
    - `playwright-skill`: Automating dashboard interaction for consistent baseline

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (must start before Change 1)
  - **Blocks**: Change 1 (requires baseline for verification)
  - **Blocked By**: None - start immediately

  **References**:
  - `index.html:40-50` - Formatting and parsing functions to preserve
  - `index.html:200-400` - Current salary and capital components

  **Acceptance Criteria**:
  - [ ] Test data created with representative scenario
  - [ ] Baseline calculations captured in JSON
  - [ ] Baseline reproducible (deterministic)
  - [ ] Baseline includes: net salary, distribution per category, RUB total, USD total, mortgage-adjusted

  **QA Scenarios**:
  \`\`\`
  Scenario: Baseline capture successful
    Tool: Playwright + Python script
    Preconditions: Current dashboard (index.html) unchanged
    Steps:
      1. Open dashboard in browser
      2. Enter test salary input: 150000 (RUB)
      3. Enter test deductions: tax 13000, insurance 7500
      4. Enter test account balances: Card 50000, Savings 200000, Deposit 300000
      5. Enter test rates: USD 80.33, Mortgage 15000000
      6. Capture all displayed values from UI
      7. Also extract localStorage fin-v3 key
      8. Save to .sisyphus/baseline/calculations.json
      9. Close browser, reopen, repeat steps 2-6
      10. Compare second run with first run
    Expected Result: Identical calculations on both runs (deterministic)
    Failure Indicators: Different results on second run, failed to capture data
    Evidence: .sisyphus/baseline/calculations.json + comparison report
  \`\`\`

  **Evidence to Capture**:
  - [ ] JSON file with baseline calculations and input data
  - [ ] Reproducibility verification report

  **Commit**: NO (baseline data, not code)

---

## CHANGE 1: dashboard-ritual-ux

**Reference**: `openspec/changes/dashboard-ritual-ux/`

**Entry Criteria:**
- Baseline calculations captured (Task -1)
- Current dashboard calculations available as behavior baseline

**Exit Criteria:**
- UX implementation preserves salary and capital calculations (matches baseline)
- Backend-dependent actions have honest placeholders or disabled states

---

---

- [ ] 1. Theme Foundation Implementation

  **What to do**:
  - Define Swiss Finance, Dark Finance, and System theme tokens using CSS custom properties
  - Replace global mono styling with sans-first text and tabular numerals where needed
  - Implement theme persistence that doesn't affect financial data
  - Add theme switcher component that updates CSS variables

  **Must NOT do**:
  - Change any calculation logic or data formats
  - Modify localStorage structure or keys
  - Break existing component functionality

  **Recommended Agent Profile**:
  > Select category + skills based on task domain. Justify each choice.
  - **Category**: `visual-engineering`
    - Reason: CSS theming, visual design, UI component changes
  - **Skills**: [`frontend-ui-ux`]
    - `frontend-ui-ux`: Creating visual themes and maintaining design consistency

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Change 1, Task 1)
  - **Blocks**: Task 2 (Navigation implementation)
  - **Blocked By**: None - start immediately

  **References** (CRITICAL - Be Exhaustive):

  > The executor has NO context from your interview. References are their ONLY guide.
  > Each reference must answer: "What should I look at and WHY?"

  **Pattern References** (existing code to follow):
  - `index.html:11-17` - Current CSS structure and font declarations
  - `index.html:14` - Current dark theme background color (`#09090b`) as base for theme tokens

  **Test References** (testing patterns to follow):
  - No test infrastructure exists - verification via manual browser testing

  **External References** (libraries and frameworks):
  - Tailwind CSS docs: `https://tailwindcss.com/docs/customizing-colors` - Theme color customization
  - CSS Custom Properties: MDN Web Docs - How CSS variables work for theming

  **WHY Each Reference Matters** (explain the relevance):
  - Don't just list files - explain what pattern/information the executor should extract
  - Current CSS structure: Use this to understand how to inject theme tokens without breaking existing styles
  - Font declarations: Sans-first text requires updating font-family from current mono-heavy approach
  - Tailwind docs: Theme tokens should integrate with existing Tailwind setup

  **Acceptance Criteria**:

  > **AGENT-EXECUTABLE VERIFICATION ONLY** - No human action permitted.
  > Every criterion MUST be verifiable by running a command or using a tool.

  - [ ] Theme tokens defined in CSS variables (Swiss Finance, Dark Finance, System)
  - [ ] Theme switcher component renders and persists preference
  - [ ] Theme changes don't affect localStorage financial data (fin-v3 key preserved)
  - [ ] Text uses sans-serif with tabular numerals for financial displays

  **QA Scenarios (MANDATORY - task is INCOMPLETE without these):**

  > **This is NOT optional. A task without QA scenarios WILL BE REJECTED.**
  >
  > Write scenario tests that verify the ACTUAL BEHAVIOR of what you built.
  > Minimum: 1 happy path + 1 failure/edge case per task.
  > Each scenario = exact tool + exact steps + exact assertions + evidence path.

  \`\`\`
  Scenario: Theme switcher works correctly
    Tool: Playwright (playwright-skill)
    Preconditions: Dashboard open in browser
    Steps:
      1. Navigate to dashboard
      2. Ensure theme switcher visible
      3. Click theme switcher button
      4. Select "Swiss Finance" theme
      5. Verify CSS variables updated
      6. Refresh page
      7. Verify theme preference persisted
    Expected Result: Theme changes visually, persists across refresh
    Failure Indicators: Theme doesn't change, or reverts to default on refresh
    Evidence: .sisyphus/evidence/change-1-theme-switch.mp4

  Scenario: Financial data not affected by theme changes
    Tool: bash + Playwright
    Preconditions: Dashboard with existing financial data in localStorage
    Steps:
      1. Open dashboard, record current localStorage (fin-v3)
      2. Change theme multiple times
      3. Compare localStorage before and after theme changes
      4. Verify keys and values identical
    Expected Result: localStorage data unchanged
    Failure Indicators: Any change to fin-v3 key or its data
    Evidence: .sisyphus/evidence/change-1-localstorage-preserved.json
  \`\`\`

  **Evidence to Capture**:
  - [ ] Video of theme switching working
  - [ ] JSON comparison of localStorage before/after theme changes

  **Commit**: YES
  - Message: `feat: add theme modes and theme switcher`
  - Files: `index.html`

---

- [ ] 2. Navigation And Screens Implementation

  **What to do**:
  - Add compact navigation for sections: `Ритуалы`, `Капитал`, `История`, `Настройки`
  - Make `Ритуалы` the default first screen on initial load
  - Add history shell with honest empty/disabled state (placeholder)
  - Add settings shell with honest empty/disabled state (placeholder)

  **Must NOT do**:
  - Break existing salary input or capital calculation components
  - Implement history/charts functionality yet (this placeholder only)
  - Implement full settings (placeholder only until needed)

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: Navigation UI, screen routing, component layout
  - **Skills**: [`frontend-ui-ux`]
    - `frontend-ui-ux`: Creating navigation patterns and screen layouts

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Change 1, Task 2)
  - **Blocks**: Task 3 (Ritual workspace)
  - **Blocked By**: Task 1 (Theme foundation)

  **References**:
  - `index.html:20` - Root div where navigation structure will be added
  - `index.html:38` - React imports needed for state management in navigation
  - `index.html:37-50` - Current component structure to integrate navigation
  - `openspec/changes/dashboard-ritual-ux/specs/dashboard-ritual-ux/spec.md:11-16` - Navigation requirements

  **Acceptance Criteria**:
  - [ ] Compact navigation visible with 4 sections: Ритуалы, Капитал, История, Настройки
  - [ ] Ритуалы section is default first screen on load
  - [ ] Navigation switches between screens correctly
  - [ ] History shell shows empty/disabled state (not fake data)
  - [ ] Settings shell shows empty/disabled state (not fake data)

  **QA Scenarios**:
  \`\`\`
  Scenario: Default screen is Ритуалы
    Tool: Playwright
    Preconditions: Fresh dashboard load
    Steps:
      1. Open dashboard URL
      2. Wait for React to render
      3. Check current screen/section is Ритуалы
    Expected Result: Ритуалы screen visible by default
    Failure Indicators: Different screen shown, or no screen shown
    Evidence: .sisyphus/evidence/change-2-default-screen.png

  Scenario: Navigation works between all 4 screens
    Tool: Playwright
    Preconditions: Dashboard loaded
    Steps:
      1. Click on navigation element for `Капитал`
      2. Verify Капитал screen shows
      3. Click on navigation element for `История`
      4. Verify История shell shows (empty state)
      5. Click on navigation element for `Настройки`
      6. Verify Настройки shell shows (empty state)
      7. Click on navigation element for `Ритуалы`
      8. Verify Ритуалы screen shows again
    Expected Result: All screens accessible, routing works
    Failure Indicators: Clicks don't navigate, wrong screen shows
    Evidence: .sisyphus/evidence/change-2-navigation.mp4

  Scenario: Empty states are honest (no fake data)
    Tool: Playwright + manual inspection
    Preconditions: Dashboard loaded
    Steps:
      1. Navigate to `История` section
      2. Verify shows empty state message (not charts/data)
      3. Navigate to `Настройки` section
      4. Verify shows shell/empty state (not full settings)
    Expected Result: Honest placeholder states, no invented data
    Failure Indicators: Fake charts, fake history data, full settings when not implemented
    Evidence: .sisyphus/evidence/change-2-honest-placeholders.png
  \`\`\`

  **Evidence to Capture**:
  - [ ] Screenshot of default screen (Ритуалы)
  - [ ] Video of navigation working
  - [ ] Screenshots of empty/shell states

  **Commit**: YES
  - Message: `feat: add navigation and screen shells`
  - Files: `index.html`

---

- [ ] 3. Ritual Workspace Implementation

  **What to do**:
  - Recompose salary inputs, deductions, net salary, and distribution into one visible-step workspace
  - Add compact capital strip from current derived totals
  - Keep finish actions visible while backend-dependent actions remain safe placeholders
  - Ensure workspace is optimized for both desktop (2-column) and mobile (single-column)

  **Must NOT do**:
  - Change calculation logic for salary or capital
  - Break existing input validation or formatting
  - Remove any existing functionality (only reorganize layout)

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: Layout reorganization, UX restructuring, responsive design
  - **Skills**: [`frontend-ui-ux`]
    - `frontend-ui-ux`: Creating cohesive workspace layouts and responsive behavior

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Change 1, Task 3)
  - **Blocks**: Task 4 (Verification)
  - **Blocked By**: Task 2 (Navigation)

  **References**:
  - `index.html:40-50` - Current formatting and parsing functions (don't change, reference for integration)
  - `index.html:200-400` (approximate range) - Current salary input and distribution components
  - `openspec/changes/dashboard-ritual-ux/specs/dashboard-ritual-ux/spec.md:19-24` - Ritual workspace requirements
  - `openspec/changes/dashboard-ritual-ux/specs/dashboard-ritual-ux/spec.md:47-56` - Responsive layout requirements

  **Acceptance Criteria**:
  - [ ] Salary inputs reorganized into single visible workspace
  - [ ] Deductions, net salary, distribution visible in workspace
  - [ ] Compact capital strip shows derived totals
  - [ ] Finish actions visible (snapshot, save placeholders)
  - [ ] Desktop: 2-column layout maintained
  - [ ] Mobile: single-column layout, no horizontal scroll

  **QA Scenarios**:
  \`\`\`
  Scenario: Workspace contains all salary components
    Tool: Playwright + manual inspection
    Preconditions: Dashboard loaded on Ритуалы screen
    Steps:
      1. Verify salary input fields visible
      2. Verify deduction fields visible
      3. Verify net salary display visible
      4. Verify distribution section visible
      5. Verify capital strip visible above or below
    Expected Result: All components in single cohesive workspace
    Failure Indicators: Components missing, scattered across screen
    Evidence: .sisyphus/evidence/change-3-workspace.png

  Scenario: Desktop 2-column layout works
    Tool: Playwright (set viewport to desktop width)
    Preconditions: Dashboard loaded, viewport set to desktop (e.g., 1200px)
    Steps:
      1. Set viewport to desktop width
      2. Verify workspace uses 2 columns
      3. Verify no horizontal scroll appears
    Expected Result: 2-column layout, no horizontal scroll
    Failure Indicators: Single column or horizontal scroll on desktop
    Evidence: .sisyphus/evidence/change-3-desktop-layout.png

  Scenario: Mobile single-column layout works
    Tool: Playwright (set viewport to mobile width)
    Preconditions: Dashboard loaded, viewport set to mobile (e.g., 375px)
    Steps:
      1. Set viewport to mobile width
      2. Verify workspace uses single column
      3. Verify no horizontal scroll appears
      4. Verify all content readable without horizontal expansion
    Expected Result: Single column, no horizontal scroll, content readable
    Failure Indicators: Horizontal scroll, content cut off, 2-column on mobile
    Evidence: .sisyphus/evidence/change-3-mobile-layout.png

  Scenario: Calculations preserved
    Tool: Playwright + comparison with baseline
    Preconditions: Baseline calculations recorded from old UI
    Steps:
      1. Record old dashboard calculations (run old version)
      2. Load new UI with same inputs
      3. Compare net salary calculation
      4. Compare distribution amounts
      5. Compare capital totals
    Expected Result: Calculations match baseline exactly
    Failure Indicators: Any calculation differs from baseline
    Evidence: .sisyphus/evidence/change-3-calculations-preserved.json
  \`\`\`

  **Evidence to Capture**:
  - [ ] Screenshot of full workspace
  - [ ] Screenshot of desktop 2-column layout
  - [ ] Screenshot of mobile single-column layout
  - [ ] Comparison JSON showing calculations unchanged

  **Commit**: YES
  - Message: `feat: implement ritual workspace with responsive layout`
  - Files: `index.html`

---

- [ ] 4. Verification for dashboard-ritual-ux

  **What to do**:
  - Run all verification tasks from tasks.md (tasks 4.1-4.4)
  - Verify desktop layout uses two columns
  - Verify mobile layout has no horizontal scroll
  - Verify salary and capital calculations match pre-redesign dashboard
  - Run `openspec status --change "dashboard-ritual-ux"`
  - Verify exit criteria met

  **Must NOT do**:
  - Skip any verification step
  - Archive change before verification complete

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Mixed verification tasks (visual + calculation + CLI)
  - **Skills**: [`playwright-skill`]
    - `playwright-skill`: Browser automation for verification

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Change 1, Task 4)
  - **Blocks**: None - after this task, change can be archived
  - **Blocked By**: Task 3 (Ritual workspace)

  **References**:
  - `openspec/changes/dashboard-ritual-ux/tasks.md:19-32` - Entry/exit criteria and verification tasks
  - `openspec/changes/dashboard-ritual-ux/specs/dashboard-ritual-ux/spec.md` - Spec requirements to verify

  **Acceptance Criteria**:
  - [ ] Desktop 2-column layout verified (task 4.1)
  - [ ] Mobile layout without horizontal scroll verified (task 4.2)
  - [ ] Salary calculations match baseline (task 4.3)
  - [ ] Capital calculations match baseline (task 4.3)
  - [ ] openspec status shows clean (task 4.4)
  - [ ] Exit criteria met: calculations preserved, placeholders honest

  **QA Scenarios**:
  \`\`\`
  Scenario: Complete verification of desktop layout
    Tool: Playwright
    Preconditions: Dashboard loaded
    Steps:
      1. Set viewport to desktop width (>~ 768px)
      2. Verify ritual workspace uses 2 columns
      3. Verify navigation visible
      4. Verify all screens accessible
    Expected Result: Desktop 2-column layout working
    Failure Indicators: Layout not 2-column, horizontal scroll
    Evidence: .sisyphus/evidence/change-4-desktop-verification.png

  Scenario: Complete verification of mobile layout
    Tool: Playwright
    Preconditions: Dashboard loaded
    Steps:
      1. Set viewport to mobile width (~375px)
      2. Verify workspace uses single column
      3. Verify navigation compact/toggleable
      4. Verify no horizontal scroll on any screen
    Expected Result: Mobile single-column layout working
    Failure Indicators: Horizontal scroll, 2-column persists
    Evidence: .sisyphus/evidence/change-4-mobile-verification.png

  Scenario: Complete verification of calculations match baseline
    Tool: Playwright + Python comparison script
    Preconditions: Baseline data captured from old version
    Steps:
      1. Create test data set (salary input, deductions, accounts)
      2. Load in new UI, capture all calculations
      3. Use Python script to compare with baseline calculations
      4. Verify all calculations match within floating-point tolerance
    Expected Result: All calculations identical to baseline
    Failure Indicators: Any calculation differs beyond tolerance
    Evidence: .sisyphus/evidence/change-4-calculations-verification.json

  Scenario: openspec status clean
    Tool: Bash
    Steps:
      1. Run `openspec status --change "dashboard-ritual-ux"`
      2. Check output shows no errors
      3. Verify all artifacts complete
    Expected Result: Clean openspec status
    Failure Indicators: Errors, incomplete artifacts, failures
    Evidence: .sisyphus/evidence/change-4-openspec-status.log
  \`\`\`

  **Evidence to Capture**:
  - [ ] Screenshots of desktop and mobile verification
  - [ ] Comparison JSON for calculations
  - [ ] openspec status log

  **Commit**: YES (final commit before archival)
  - Message: `test: verify dashboard-ritual-ux complete and ready for archive`
  - Files: No new files, verification evidence only

---

## Next Phase Preparation

**After Change 1 (dashboard-ritual-ux) is complete and verified:**

1. **Run Inter-Change Validation**:
   ```bash
   # Verify change is ready for archival
   openspec status --change "dashboard-ritual-ux"
   # Expected: All artifacts complete, no errors

   # Verify exit criteria from tasks.md
   # - UX implementation preserves salary and capital calculations ✓
   # - Backend-dependent actions have honest placeholders ✓

   # Check that Change 2 (backend-foundation) doesn't depend on undocumented details
   grep -r "dashboard-ritual-ux" openspec/changes/backend-foundation/
   # Expected: No references to undocumented implementation details
   ```

2. **Archive Change 1**:
   ```bash
   openspec archive "dashboard-ritual-ux"
   # Expected: Change moved to openspec/changes/archive/
   ```

3. **Proceed to Change 2**:
   - Start backend-foundation implementation only after archival
   - Verify Change 2 entry criteria: product contract definitions available
   - Review Change 2 spec for any changes needed based on Change 1 implementation

---

## Final Verification Wave (MANDATORY — after ALL 4 changes complete)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.
>
> **Do NOT auto-proceed after verification. Wait for user's explicit approval before marking work complete.**
> **Never mark F1-F4 as checked before getting user's okay.** Rejection or user feedback -> fix -> re-run -> present again -> wait for okay.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, curl endpoint, run command). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in .sisyphus/evidence/. Verify all 4 changes implemented and archived in correct sequence.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Changes [N/N] | Sequence [CORRECT/VIOLATED] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Check for obvious issues in index.html: console.log in prod, empty catches, commented-out code unused imports (script tags). Check backend code for similar issues. Check AI slop: excessive comments, over-abstraction, generic names (data/result/item/temp). Verify formatting matches project conventions.
  Output: `Lint [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high` (+ `playwright-skill`)
  Start from clean state. Execute EVERY QA scenario from EVERY task across all 4 changes — follow exact steps, capture evidence. Test cross-change integration (features working together across changes). Test edge cases: empty state, invalid input, rapid actions, network failures. Save to `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [N/N] | Cross-Change [N/N] | Edge Cases [N tested] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task across all 4 changes: read "What to do", read actual diff (git log/diff). Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance. Detect cross-task contamination: Task N in Change M touching files from Change N-1. Flag unaccounted changes. Verify sequential execution was maintained (no parallel work, correct archiving).
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | Sequence [MAINTAINED/VIOLATED] | VERDICT`

---

## Commit Strategy

- **Task 1**: `feat: add theme modes and theme switcher` - index.html theme tokens
- **Task 2**: `feat: add navigation and screen shells` - index.html navigation
- **Task 3**: `feat: implement ritual workspace with responsive layout` - index.html workspace
- **Task 4**: `test: verify dashboard-ritual-ux complete` + `archive: dashboard-ritual-ux`

Subsequent changes will follow similar commit patterns per change.

---

## Success Criteria

### Verification Commands
```bash
# Check Change 1 archived
ls openspec/changes/archive/ | grep "dashboard-ritual-ux"
# Expected: Directory exists

# Check dashboard has new UI features
grep -c "theme-" index.html
# Expected: > 0 (theme tokens defined)

grep -c "Ритуалы\|Капитал\|История\|Настройки" index.html
# Expected: > 0 (navigation present)

# Check responsive layout
# Manual check via browser: open index.html at different viewport sizes
# Expected: 2-column on desktop, single-column on mobile, no horizontal scroll

# Compare calculations (needs baseline)
python3 scripts/compare-calculations.py --old baseline.json --new current.json
# Expected: All calculations match within tolerance
```

### Final Checklist (after all 4 changes)
- [ ] All 4 changes archived in correct sequence
- [ ] Dashboard has theme modes and navigation
- [ ] Backend with SQLite and API works independently
- [ ] Dashboard migrated to backend API
- [ ] Salary events and snapshots system working
- [ ] All calculations preserved across changes
- [ ] localStorage data migrated, not lost
- [ ] All verification steps passed
- [ ] All QA scenarios executed with evidence

---

## Risk Register and Mitigation Strategies

**This section catalogs all identified risks, their mitigation actions, and contingency plans.**

### Risk 1: Change 2 (Backend) Becomes Critical Bottleneck

**Description**: Change 2 is the longest change (5 days) and blocks Changes 3 and 4. If backend architecture has hidden complexity or tech stack surprises, entire project stalls.

**Probability**: Medium - Backend work often takes longer than estimated
**Impact**: High - Blocks 2 subsequent changes

**Mitigation Actions (PRE-IMPLEMENTED):**
- ✅ Spike validation built into plan: 1-day minimal skeleton before full Change 2
- ✅ Decision gate: Only proceed if spike proves all assumptions valid
- ✅ Timeboxing: 5-day estimate with 50% buffer (stop at 7.5 days and reassess)

**Contingency Plan (If Mitigation Fails):**
- Plan B: Simplify backend scope - defer advanced features (e.g., complex seed script) to later change
- Plan C: Reconsider tech stack if spike shows FastAPI/SQLAlchemy unsuitable for project
- Plan D: Parallel UI work: Start Change 3 UI restructuring while backend issues resolved (requires updating change sequence)

**Owner**: Change 2 implementation agent
**Trigger**: Spike completion shows problems OR 7.5-day timebox exceeded

---

### Risk 2: No Rollback Path for Change 3 (API Migration)

**Description**: Once dashboard depends on backend API, if backend fails or data corruption occurs, users have zero fallback to working app.

**Probability**: Medium - API integration often has edge cases
**Impact**: High - Users could lose access to their financial tracking completely

**Mitigation Actions (PLANNED FOR CHANGE 3):**
- Fallback mode: Read-only access when backend unavailable for > 10 seconds
- Cache last known good state in localStorage (separate key, not fin-v3)
- Clear error messages when backend fails (not silent failures)
- Disable save actions when backend unavailable with honest messaging

**Contingency Plan (If Mitigation Fails):**
- Plan B: Implement temporary localStorage write-back option for emergency use
- Plan C: Keep old dashboard version accessible via different URL (legacy mode)
- Plan D: Manual data export/import CSV option for backup purposes

**Owner**: Change 3 implementation agent
**Trigger**: Backend failures during testing OR users report data loss concerns

---

### Risk 3: Calculation Precision Loss During Migration

**Description**: Floating-point operations, string parsing, or rounding could differ between old and new implementations, causing financial miscalculations.

**Probability**: Low - Parse/fmt functions are simple
**Impact**: Critical - Financial data integrity compromised

**Mitigation Actions (PRE-IMPLEMENTED):**
- ✅ Baseline capture before any changes (Task -1)
- ✅ Guardrail: "Preserve exact parse/fmt function behavior"
- ✅ Comparison tolerance: 0.01 RUB acceptable for verification
- ✅ Every QA scenario in Change 1 includes calculation comparison

**Contingency Plan (If Mitigation Fails):**
- Plan B: Use decimal.js library for precise financial calculations
- Plan C: Parse/fmt function validation test suite with edge cases (null, "", " ", 1.2345, comma separators)
- Plan D: Manual audit of all calculation code paths by finance-savvy reviewer

**Owner**: Change 1 implementation agent (baseline capture)
**Trigger**: ANY calculation mismatch in verification scenarios

---

### Risk 4: Inter-Change Contract Breakage

**Description**: Implementation of Change N discovers a bug or limitation in Change N-1's design, requiring modifications to archived change.

**Probability**: Medium - Hidden dependencies often discovered during implementation
**Impact**: Medium - Re-opening archived changes violates sequential workflow premise

**Mitigation Actions (IN PLAN):**
- ✅ Smoke test previous changes before starting next change
- ✅ Dependency graph validation from spec text before implementation
- ✅ Contract update protocol: STOP → update spec → resume
- ✅ Documentation of all discovery notes in `.sisyphus/discovery.md`

**Contingency Plan (If Mitigation Fails):**
- Plan A: Determine if issue is changeable or must create new change for "fixes"
- Plan B: If unarchive exists (verify `openspec unarchive <change>` works): Update archived change
- Plan C: If unarchive not available: Create Change 5 "backend-foundation-fixes" after 4 changes
- Plan D: Document workaround in plan and proceed (only if issue is minor and non-blocking)

**Owner**: Implementation agent who discovers the issue
**Trigger**: Discovery of contract issue that blocks current implementation

---

### Risk 5: Manual Verification Doesn't Scale / Is Error-Prone

**Description**: 4 changes × ~5 QA scenarios each = 20+ manual browser checks. Human error, fatigue, and lack of reproducibility.

**Probability**: High - Manual verification is inherently error-prone
**Impact**: Medium - Could miss regressions or integration issues

**Mitigation Actions (WILL BE CONSIDERED):**
- QA scenarios are ultra-detailed with exact steps (reduce human error)
- Evidence capture required for every scenario (audit trail)
- Final verification wave uses parallel agents (4 agents for comprehensive check)
- End-to-end integration scenario in final wave catches integration issues

**Contingency Plan (If Mitigation Fails):**
- Plan A: Create automated Playwright test script if time permits during implementation
- Plan B: Pair verification: One agent executes, another reviews evidence
- Plan C: Stagger verification: Do partial verification after each change, full final verification
- Plan D: Accept higher manual effort (acknowledge risk, mitigate via detailed documentation)

**Owner**: Plan orchestrator (me)
**Trigger**: Verification fatigue OR missed regression detected in final wave

---

### Risk 6: openspec CLI Unexpected Behavior

**Description**: `/opt/homebrew/bin/openspec status` may have different output format than assumed, breaking verification logic.

**Probability**: Low - CLI tool is stable, but possible
**Impact**: Medium - Cannot rely on automated status checks, slows down workflow

**Mitigation Actions (PRE-IMPLEMENTED):**
- ✅ Test openspec status on existing change before starting workflow
- ✅ Document actual output format in plan/draft
- ✅ Build verification script that handles multiple output formats if needed

**Contingency Plan (If Mitigation Fails):**
- Plan A: Manual verification if CLI behavior differs from expected
- Plan B: File issue with openspec, wait for fix (delays workflow)
- Plan C: Workaround: Use git status and directory structure as alternative status checks
- Plan D: Build custom verification script using openspec's file structure

**Owner**: Plan orchestrator (first step before Change 1)
**Trigger`: openspec status command fails or returns unexpected format

---

### Risk 7: localStorage Data Migration Edge Cases

**Description**: Real user data may be corrupted, partial, or missing required fields. Import may fail silently or crash app.

**Probability**: Medium - User data often has edge cases
**Impact**: Critical - Data loss or corruption during migration

**Mitigation Actions (PLANNED FOR CHANGE 3):**
- Validate import behavior with schema-variant test data
- Test with malformed JSON, missing fields, wrong types
- Explicit warning before import: "Import will overwrite backend data. Continue?"
- Import with transaction: Complete success or complete rollback

**Contingency Plan (If Mitigation Fails):**
- Plan A: Create schema migration tool that transforms legacy formats
- Plan B: Manual data export from localStorage (developer tool) and manual backend insert
- Plan C: Support for multiple legacy schema versions, not just current v3
- Plan D: If data loss risk high: Defer import feature, require manual data entry after migration

**Owner**: Change 3 implementation agent
**Trigger`: Import test cases fail OR data loss during development

---

### Risk 8: Sequential Timeline Overruns

**Description**: Strict sequential execution means project timeline is sum of all changes. Unlikely but possible: one change takes much longer than estimated.

**Probability**: Low-Medium - Backend surprises are the main risk
**Impact**: Medium - Project delayed, resources constrained

**Mitigation Actions (IN PLAN):**
- ✅ Timeboxing with checkpoint after each 50% buffer exceeded
- ✅ Spike validation reduces Change 2 risk significantly
- ✅ Conservative estimates (Change 2: 5 days, includes buffer)
- ✅ Decision gates: Stop, reassess, get approval before continuing

**Contingency Plan (If Mitigation Fails):**
- Plan A: Reduce scope - defer non-essential features to later changes
- Plan B: Parallel low-risk work (e.g., documentation) while critical path unblocks
- Plan C: Accept delay - communicate early to stakeholders
- Plan D: Phase delivery: Ship working partial system after Change 2 (backend + old UI)

**Owner**: Project lead / user decision at timebox checkpoints
**Trigger`: 50% buffer exceeded for any change (e.g., Change 2 takes > 7.5 days)

---

### Risk Matrix Summary

| Risk | Probability | Impact | Primary Mitigation | Contingency Ready |
|------|-------------|--------|-------------------|-------------------|
| Backend bottleneck | Medium | High | Spike validation (1 day) | Yes, 3 options |
| No rollback for API migration | Medium | High | Fallback mode design | Yes, 3 options |
| Calculation precision loss | Low | Critical | Baseline capture, guardrails | Yes, 3 options |
| Contract breakage | Medium | Medium | Smoke testing, protocol | Yes, 4 options |
| Manual verification error | High | Medium | Detailed scenarios, parallel agents | Yes, 4 options |
| openspec CLI issues | Low | Medium | Test CLI before workflow | Yes, 3 options |
| Data migration edge cases | Medium | Critical | Validation tests, warnings | Yes, 4 options |
| Timeline overrun | Low-Medium | Medium | Timeboxing, spikes | Yes, 4 options |

---

## Note: Partial Plan with Key Enhancements

This plan contains:
- **Complete Change 1 (dashboard-ritual-ux)** with all tasks and QA scenarios
- **Pre-implementation baseline capture** (Task -1) to ensure no regression
- **Expanded guardrails** addressing all Metis-identified gaps
- **Risk register** with 8 major risks, mitigations, and contingency plans
- **Inter-change validation protocol** with smoke testing and contract handling
- **Timeboxing and decision gates** to prevent runaway timeline

**Changes 2-4 (backend-foundation, dashboard-api-migration, salary-events-snapshots) structure established but will be expanded in subsequent updates following the same detailed pattern.**

The comprehensive foundation is now complete for consistent execution across all 4 sequential changes with risk mitigation at every step.

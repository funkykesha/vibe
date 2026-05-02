## ADDED Requirements

### Requirement: Post-research spec rebuild
The project SHALL rebuild the active finance OpenSpec changes after the research gate completes and before production implementation resumes.

#### Scenario: Start roadmap rebuild
- **WHEN** the research gate is archived and active finance planning changes remain open
- **THEN** the project SHALL treat those active changes as inputs to a spec rebuild rather than as direct implementation queues
- **THEN** the rebuild SHALL identify which existing changes are kept, changed, split, deferred, dropped, or archived

### Requirement: Rebuilt implementation sequence
The spec rebuild SHALL produce an ordered implementation sequence whose stages can be completed and verified independently.

#### Scenario: Define stage order
- **WHEN** the rebuilt roadmap is prepared
- **THEN** it SHALL order stages as product contract normalization, dashboard ritual UX redesign, backend foundation and config, dashboard API migration, salary events and snapshots, Telegram assistant, TBank sync, deployment readiness, and deferred OCR/photo flow unless a documented research verdict changes that order

#### Scenario: Preserve dependency direction
- **WHEN** a later stage depends on shared state, account identity, snapshot semantics, or external provider mapping
- **THEN** the earlier stage SHALL define the required contract before the later stage is marked ready

### Requirement: Replacement change boundaries
The spec rebuild SHALL create or update OpenSpec changes so each replacement change has a narrow responsibility and a clear user-visible or system-visible outcome.

#### Scenario: Split broad planning changes
- **WHEN** requirements are moved from `finance-product-rituals`, `finance-product-design-system`, or `finance-automation-system`
- **THEN** the project SHALL place them into replacement changes with coherent boundaries instead of leaving duplicate competing requirements in the old broad changes

#### Scenario: Defer future work
- **WHEN** a requirement belongs to deployment, historical import, OCR, broad provider automation, or another non-MVP area
- **THEN** the project SHALL mark it as deferred or move it into a later replacement change rather than mixing it into the first implementation stage

### Requirement: Stage handoff gates
Each rebuilt implementation change SHALL define entry criteria, exit criteria, verification, and handoff artifacts.

#### Scenario: Prepare a stage for implementation
- **WHEN** a replacement implementation change is created
- **THEN** its proposal, design, specs, or tasks SHALL state what must already be true before the stage starts
- **THEN** they SHALL state what must be verified before the next stage can start
- **THEN** they SHALL identify any data contracts, API contracts, UI states, or user-visible behaviors handed to later stages

### Requirement: Research evidence carry-forward
The spec rebuild SHALL preserve research evidence needed for implementation decisions without duplicating irrelevant research prose.

#### Scenario: Carry external dependency evidence
- **WHEN** a replacement change depends on external library, framework, API, provider, browser, or hosting behavior
- **THEN** the replacement change SHALL cite the relevant Context7 check from the research gate or record the fallback source, retrieval date, confidence level, and impact on the stage

#### Scenario: Avoid unsupported implementation assumptions
- **WHEN** a replacement change makes a technical decision that was not covered by the research gate
- **THEN** the change SHALL either add a narrow pre-implementation spike or mark the decision as unresolved before implementation starts

### Requirement: No production implementation in roadmap rebuild
The spec rebuild SHALL only change OpenSpec planning artifacts and related implementation-plan documents.

#### Scenario: Apply roadmap rebuild change
- **WHEN** this roadmap rebuild change is implemented
- **THEN** production app files such as `index.html`, backend code, bot code, provider code, and deployment code SHALL remain unchanged
- **THEN** only OpenSpec changes, specs, tasks, and planning documents SHALL be created or edited

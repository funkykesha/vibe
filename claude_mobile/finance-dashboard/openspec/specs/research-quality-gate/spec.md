# research-quality-gate Specification

## Purpose
TBD - created by archiving change research-spec-quality-plan. Update Purpose after archive.
## Requirements
### Requirement: Blocking research gate
The project SHALL complete a research and spec-quality gate before starting or continuing any implementation stage from the current finance roadmap.

#### Scenario: Implementation requested before gate completion
- **WHEN** an implementation stage is requested before the research gate has complete verdicts
- **THEN** the project SHALL treat the stage as blocked until the relevant research, audit, and roadmap impact outputs exist

### Requirement: Existing spec audit
The research gate SHALL audit the existing `finance-product-rituals`, `finance-automation-system`, and `finance-product-design-system` changes for contradictions, missing contracts, unsafe assumptions, and roadmap gaps.

#### Scenario: Audit current OpenSpec changes
- **WHEN** the audit is performed
- **THEN** it SHALL compare product requirements, technical decisions, design decisions, stage ordering, data model assumptions, API contracts, UI constraints, and out-of-scope boundaries across the existing changes

### Requirement: Stage verdicts
The research gate SHALL produce a `keep`, `change`, `split`, or `drop` verdict for every current roadmap stage.

#### Scenario: Classify current stages
- **WHEN** research for a stage is complete
- **THEN** the decision log SHALL record the stage name, verdict, rationale, evidence, and downstream roadmap impact

### Requirement: Mini spikes for architecture-changing risks
The research gate SHALL include small evidence-focused spikes for risks that can change architecture, dependencies, deployment, or data safety.

#### Scenario: Validate external or architectural risk
- **WHEN** a risk can invalidate the planned architecture
- **THEN** the gate SHALL require a mini spike or documented proof before assigning a final stage verdict

### Requirement: Context7 documentation checks
The research gate SHALL use Context7 documentation checks for external libraries, frameworks, APIs, and hosting platforms before making research verdicts that depend on them.

#### Scenario: Research external dependency
- **WHEN** a verdict depends on behavior or configuration of an external dependency
- **THEN** the research output SHALL resolve the Context7-compatible library ID before querying documentation
- **THEN** the research output SHALL cite a Context7 documentation check or record that Context7 was unavailable or lacked coverage
- **THEN** each Context7 record SHALL include dependency name, resolved Context7 library ID, resolved documentation source, retrieved topics, retrieval date, and impact on the verdict

#### Scenario: Use fallback documentation source
- **WHEN** Context7 is unavailable or does not cover the dependency
- **THEN** the research output SHALL record the fallback source, retrieval date, confidence level, and reason for fallback before assigning the verdict

### Requirement: Roadmap impact output
The research gate SHALL produce roadmap impact notes that explain how the implementation pipeline should be rebuilt after research.

#### Scenario: Prepare roadmap rewrite
- **WHEN** all stage verdicts are complete
- **THEN** the gate SHALL identify which future changes should be created, merged, split, reordered, deferred, or removed

### Requirement: Product design system audit
The research gate SHALL evaluate whether `finance-product-design-system` is ready to drive implementation.

#### Scenario: Audit design system readiness
- **WHEN** the design system audit is performed
- **THEN** the gate SHALL check theme feasibility, responsive layout risk, current UI migration constraints, first-screen information hierarchy, and consistency with ritual-first product requirements

#### Scenario: Discover design-relevant finding
- **WHEN** research finds a product flow, interface state, theme, or layout issue
- **THEN** the finding SHALL be recorded as input for `finance-product-design-system` or the rebuilt implementation roadmap without implementing the UI


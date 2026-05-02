## MODIFIED Requirements

### Requirement: Roadmap impact output
The research gate SHALL produce roadmap impact notes that explain how the implementation pipeline should be rebuilt after research, and those notes SHALL be consumed by a concrete post-research spec rebuild before implementation resumes.

#### Scenario: Prepare roadmap rewrite
- **WHEN** all stage verdicts are complete
- **THEN** the gate SHALL identify which future changes should be created, merged, split, reordered, deferred, or removed

#### Scenario: Consume roadmap findings
- **WHEN** the research gate has been archived and implementation is requested
- **THEN** the project SHALL complete a spec-roadmap rebuild that converts the roadmap impact notes into updated active OpenSpec changes before production implementation begins

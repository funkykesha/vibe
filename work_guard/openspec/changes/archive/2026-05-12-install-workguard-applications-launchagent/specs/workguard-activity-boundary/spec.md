## ADDED Requirements

### Requirement: ActivitySignals remains future boundary
The system SHALL document `ActivitySignals` only as a future interface boundary for local, coarse-grained activity semantics in this change.

#### Scenario: Rebuild change does not add collectors
- **WHEN** this change is implemented
- **THEN** no `ActivitySignals` collectors are added
- **THEN** no `ActivitySignals` ingestion pipeline is added
- **THEN** no `ActivitySignals` export pipeline is added

### Requirement: Future activity boundary remains local and coarse
Any `ActivitySignals` documentation introduced by this change SHALL describe only local, coarse-grained activity semantics.

#### Scenario: Activity boundary is documented
- **WHEN** documentation mentions `ActivitySignals`
- **THEN** it describes a future local boundary
- **THEN** it does not specify fine-grained capture, outbound transfer, or implemented collectors

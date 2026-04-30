## MODIFIED Requirements

### Requirement: Display model availability status during server startup

The system SHALL display real-time status of all available Eliza models during server startup, showing which models are accessible and which are unavailable.

#### Scenario: Server startup with sequential probing
- **WHEN** server starts (`npm start`) and begins probing models sequentially
- **THEN** initial group list is displayed with ⏳ for all models
- **AND** as each model completes probing (3-5 seconds apart), that model's status updates (✅ or ❌)
- **AND** when all models in a provider group are done, group is displayed with final statuses

#### Scenario: Per-model update
- **WHEN** each individual model completes probing
- **THEN** that model's status in the provider group updates immediately
- **AND** progress bar is recalculated and shown

## MODIFIED Requirements

### Requirement: Display model availability status during server startup

The system SHALL display real-time status of all available Eliza models during server startup, showing which models are accessible and which are unavailable.

#### Scenario: Server startup with model probing
- **WHEN** server starts (`npm start`) and begins probing models
- **THEN** initial group list SHALL be displayed with ⏳ for all models
- **AND** as each provider's probe completes, that group SHALL be re-displayed with final statuses

#### Scenario: Completed model group display
- **WHEN** all models in a provider group have completed probing
- **THEN** the group SHALL be shown with format: `ProviderName [████░░░░] 12/15` followed by model list
- **AND** the progress bar shows 100% filled (`[██████████]`)
- **AND** models SHALL show ✅ for available, ❌ for unavailable

#### Scenario: Race condition safety
- **WHEN** probe events arrive before provider map is initialized
- **THEN** those events SHALL be queued and processed once initialization completes
- **AND** no events SHALL be silently dropped

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

#### Scenario: Sequential provider display with line rewriting
- **WHEN** providers complete their first model probe
- **THEN** provider groups are displayed sequentially in order of completion
- **AND** existing provider lines are rewritten (not appended) when model statuses update
- **AND** a global progress indicator is shown at the bottom showing total completion across all providers

### Requirement: Update groups incrementally without full screen redraw
The system SHALL update individual provider groups as models complete without clearing the entire screen or causing terminal flicker.

#### Scenario: Group in-progress update with line rewriting
- **WHEN** a model completes in an already-displayed group
- **THEN** only that group's lines are updated (progress bar and model list) using terminal cursor positioning
- **AND** output is re-rendered cleanly without clearing other groups
- **AND** the global progress bar at the bottom is updated with new completion statistics

#### Scenario: Global progress tracking
- **WHEN** any model completes probing across all providers
- **THEN** a global progress indicator is displayed at the bottom of the output showing total models probed vs total models
- **AND** this global indicator is updated incrementally as each model completes
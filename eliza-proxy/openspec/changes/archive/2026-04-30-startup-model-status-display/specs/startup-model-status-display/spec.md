## ADDED Requirements

### Requirement: Real-time model status display during startup
The system SHALL display a real-time status of model availability probing during application startup, showing progress bars and color-coded status indicators for each model.

#### Scenario: Application startup with model probing
- **WHEN** the application starts and begins probing models
- **THEN** a real-time display shows progress bars and status indicators for each model

### Requirement: Progress bar visualization
The system SHALL display a 20-character progress bar for each provider group showing the completion percentage of model probing.

#### Scenario: Model probing progress
- **WHEN** models are being probed
- **THEN** a progress bar updates in real-time showing the percentage of completed probes

### Requirement: Color-coded status indicators
The system SHALL display color-coded status indicators for each model:
- ✅ (green) for successful probes
- ❌ (red) for failed probes
- ⏳ (yellow) for pending probes

#### Scenario: Model status updates
- **WHEN** a model probe completes successfully
- **THEN** the model indicator changes to a green ✅

#### Scenario: Model probe failure
- **WHEN** a model probe fails
- **THEN** the model indicator changes to a red ❌

#### Scenario: Model probe pending
- **WHEN** a model probe is initiated but not yet complete
- **THEN** the model indicator shows a yellow ⏳

### Requirement: Dynamic terminal updates
The system SHALL update the display dynamically in the terminal without excessive screen flickering, using ANSI escape codes for efficient redrawing.

#### Scenario: Display updates
- **WHEN** model statuses change
- **THEN** the terminal display updates efficiently without flickering

### Requirement: Provider grouping
The system SHALL group models by provider and display each provider group with its progress bar and model list.

#### Scenario: Multiple providers
- **WHEN** models from multiple providers are being probed
- **THEN** each provider is displayed in its own group with separate progress tracking
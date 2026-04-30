## Purpose

Display real-time model availability status during server startup using sequential probing with per-model status updates.
## Requirements
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

### Requirement: Group models by provider

The system SHALL organize models by their provider (OpenAI, Anthropic, Google, etc.) and display each provider as a separate group.

#### Scenario: Multiple providers
- **WHEN** models from different providers are being probed
- **THEN** each provider appears as a distinct group in output
- **AND** groups appear in order of when their first model completes probing

#### Scenario: Single provider
- **WHEN** only one provider has models
- **THEN** that provider group is displayed with all its models

### Requirement: Display model status with visual indicators

The system SHALL show the availability status of each model using visual indicators: ✅ for available, ❌ for failed, ⏳ for probing.

#### Scenario: Available model
- **WHEN** a model's probe completes successfully (HTTP 200)
- **THEN** model is displayed as `✅ model-name` in green color

#### Scenario: Failed model
- **WHEN** a model's probe fails (any non-200 status)
- **THEN** model is displayed as `❌ model-name` in red color

#### Scenario: Probing model
- **WHEN** a model is currently being probed
- **THEN** model is displayed as `⏳ model-name` without color

### Requirement: Format model list inline with wrapping

The system SHALL display models as a comma-separated inline list that wraps to multiple lines if needed.

#### Scenario: Models fit on one line
- **WHEN** provider has few models and all fit within terminal width
- **THEN** all models are shown on a single indented line: `  ✅ model-a, ✅ model-b, ❌ model-c`

#### Scenario: Models span multiple lines
- **WHEN** provider has many models or model names are long
- **THEN** models wrap to additional indented lines without breaking individual model entries
- **AND** subsequent lines maintain the same indentation as first line

#### Scenario: Terminal width constraints
- **WHEN** rendering model list
- **THEN** system attempts to fit models within 80-100 character line width
- **AND** wraps gracefully without cutting model names

### Requirement: Use ANSI color codes for terminal output

The system SHALL use ANSI escape codes to color-code status indicators and provider headers.

#### Scenario: Color output
- **WHEN** outputting model status
- **THEN** ✅ uses green (`\x1b[32m`), ❌ uses red (`\x1b[31m`), provider name uses yellow (`\x1b[33m`)
- **AND** all output is reset to default color (`\x1b[0m`) after each line

#### Scenario: Graceful degradation
- **WHEN** terminal doesn't support ANSI codes
- **THEN** output still displays correctly (symbols and text visible without colors)

### Requirement: Update groups incrementally without full screen redraw

The system SHALL append new groups to output as they complete without clearing the entire screen or causing terminal flicker.

#### Scenario: New group appears
- **WHEN** a new provider group completes its first model
- **THEN** that group is printed to stdout as new lines
- **AND** previously printed groups remain visible above it

#### Scenario: Group in-progress update
- **WHEN** a model completes in an already-displayed group
- **THEN** only that group's lines are updated (progress bar and model list)
- **AND** output is re-rendered cleanly without clearing other groups

#### Scenario: No screen flicker
- **WHEN** models complete during probing
- **THEN** terminal output appears smooth and readable
- **AND** no visual artifacts or excessive redrawing occurs

### Requirement: Progress bar format and calculation

The system SHALL display a progress bar showing the count of completed models vs total models in each provider group.

#### Scenario: Progress bar display
- **WHEN** rendering a provider group
- **THEN** progress bar is shown as `[████░░░░] X/Y` where:
  - `████` represents completed models (filled)
  - `░░░░` represents remaining models (empty)
  - Bar width is fixed at 20 characters
  - X = number of models with completed probe (success or failure)
  - Y = total models in the provider

#### Scenario: 100% completion
- **WHEN** all models in a provider have completed probing
- **THEN** entire bar is filled: `[██████████████████████]`
- **AND** progress bar remains visible in output (not removed)

#### Scenario: Bar calculation
- **WHEN** provider has 15 models and 5 have completed probe
- **THEN** bar displays 5/15 with progress: `[████████░░░░░░░░░░░░] 5/15`


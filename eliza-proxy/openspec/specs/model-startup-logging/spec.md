## Purpose

Display catalog readiness and optional diagnostic probe health during server startup without treating probe warnings as catalog unavailability.

## Requirements
### Requirement: Display model availability status during server startup
The system SHALL display catalog readiness and optional model health during server startup without running paid model probes by default.

#### Scenario: Server startup without explicit probe mode
- **WHEN** server starts (`npm start`) and obtains the model catalog
- **THEN** initial provider groups SHALL be displayed from deterministic catalog rules
- **AND** the server SHALL continue accepting HTTP requests without waiting for model probes
- **AND** the server SHALL NOT send real model completion requests solely to validate the catalog

#### Scenario: Server startup with explicit probe mode
- **WHEN** server starts with an explicit probe flag or probe environment option
- **THEN** initial provider groups SHALL be displayed with `pending` diagnostic probe status for models in probe scope
- **AND** the server SHALL continue accepting HTTP requests while probing continues in the background
- **AND** as model probes complete, existing displayed groups SHALL be updated with diagnostic probe health states

#### Scenario: Completed diagnostic model group display
- **WHEN** all models in a provider group have completed probing
- **THEN** the group SHALL be shown with format: `ProviderName [████░░░░] 12/15` followed by model list
- **AND** the progress bar shows 100% filled when every model in that provider has final probe state
- **AND** models SHALL show distinct diagnostic indicators for `success`, `warning`, and `error`

#### Scenario: Race condition safety
- **WHEN** optional probe events arrive before provider map is initialized
- **THEN** those events SHALL be queued and processed once initialization completes
- **AND** no events SHALL be silently dropped
- **AND** queued events SHALL update the seeded model list rather than creating duplicate model entries

### Requirement: Group models by provider
The system SHALL organize models by their provider and display each provider as a separate stable group.

#### Scenario: Multiple providers
- **WHEN** models from different providers are being probed
- **THEN** each provider appears as a distinct group in output
- **AND** groups appear in deterministic provider order based on the seeded catalog

#### Scenario: Single provider
- **WHEN** only one provider has models
- **THEN** that provider group is displayed with all its models

#### Scenario: Provider receives later updates
- **WHEN** a probe update arrives for a model in an already displayed provider
- **THEN** that provider remains in the same output position
- **AND** only the model status and progress counts change

### Requirement: Display model status with visual indicators
The system SHALL show catalog and optional probe health using visual indicators for `available`, `unsupported`, `preview`, `pending`, `success`, `warning`, and `error`.

#### Scenario: Catalog available model
- **WHEN** a model is compatible with the proxy chat path
- **THEN** model is displayed as `available`
- **AND** the terminal indicator uses green success styling

#### Scenario: Preview model
- **WHEN** a compatible model is marked with `stability: preview`
- **THEN** model is displayed with preview styling distinct from stable available models

#### Scenario: Unsupported model
- **WHEN** a catalog model is excluded because it is non-chat or unsupported by the proxy chat path
- **THEN** it is not shown in default selectable startup output
- **AND** diagnostics can expose it as `unsupported`

#### Scenario: Successful diagnostic probe
- **WHEN** explicit probe mode is enabled and a model's probe completes successfully with response text
- **THEN** model diagnostic status is displayed as `success`
- **AND** the terminal indicator uses green success styling

#### Scenario: Warning diagnostic probe
- **WHEN** explicit probe mode is enabled and a model probe times out, hits quota, returns empty output, or fails with retryable request shape/provider behavior
- **THEN** model diagnostic status is displayed as `warning`
- **AND** the model remains considered selectable if catalog capability rules mark it compatible
- **AND** the terminal indicator uses warning styling distinct from hard errors

#### Scenario: Hard diagnostic probe error
- **WHEN** explicit probe mode is enabled and a model probe fails due to auth, access denial, model not found, or hard endpoint failure
- **THEN** model diagnostic status is displayed as `error`
- **AND** the terminal indicator uses red error styling

#### Scenario: Probing model
- **WHEN** explicit probe mode is enabled and a model has not reached final probe state
- **THEN** model diagnostic status is displayed as `pending`

### Requirement: Format model list inline with wrapping
The system SHALL display models as a comma-separated inline list that wraps to multiple lines without relying on terminal auto-wrap.

#### Scenario: Models fit on one line
- **WHEN** provider has few models and all fit within terminal width
- **THEN** all models are shown on a single indented line

#### Scenario: Models span multiple lines
- **WHEN** provider has many models or model names are long
- **THEN** models wrap to additional indented lines without breaking individual model entries
- **AND** subsequent lines maintain the same indentation as first line

#### Scenario: Terminal width constraints
- **WHEN** rendering model list in a TTY
- **THEN** system uses the current terminal width to choose wrapping boundaries
- **AND** wraps gracefully without cutting model names

#### Scenario: Non-TTY output
- **WHEN** output is redirected to logs
- **THEN** system avoids cursor movement control codes
- **AND** output remains readable as plain snapshots

### Requirement: Use ANSI color codes for terminal output
The system SHALL use ANSI escape codes to color-code status indicators when supported.

#### Scenario: Color output
- **WHEN** outputting model status to a color-capable terminal
- **THEN** success uses green, error uses red, warning uses yellow, and pending remains visually distinct
- **AND** all output is reset to default color after each colored segment

#### Scenario: Graceful degradation
- **WHEN** terminal doesn't support ANSI codes
- **THEN** output still displays correctly with visible symbols and text

### Requirement: Update groups incrementally without full screen redraw
The system SHALL update displayed status cleanly without line merging, terminal flicker, or unbounded output growth.

#### Scenario: Group in-progress update with line rewriting
- **WHEN** a model completes in an already-displayed group
- **THEN** rendered output is updated in place when stdout is a TTY
- **AND** output is re-rendered cleanly without leaving stale wrapped lines
- **AND** global progress is updated with new completion statistics

#### Scenario: Global progress tracking
- **WHEN** any model completes probing across all providers
- **THEN** a global progress indicator is displayed showing total models with final probe state vs total models
- **AND** this global indicator is updated incrementally as each model completes

#### Scenario: Final probe summary
- **WHEN** all model probes complete
- **THEN** the terminal display includes final counts for `success`, `warning`, and `error`

### Requirement: Progress bar format and calculation
The system SHALL display progress bars based on final probe state count, not probe success count.

#### Scenario: Progress bar display
- **WHEN** rendering a provider group
- **THEN** progress bar is shown as `[████░░░░] X/Y` where X is the number of models with final probe state and Y is total models in the provider
- **AND** final probe states include `success`, `warning`, and `error`

#### Scenario: 100% completion
- **WHEN** all models in a provider have completed probing
- **THEN** entire bar is filled
- **AND** progress bar remains visible in output

#### Scenario: Bar calculation
- **WHEN** provider has 15 models and 5 have final probe state
- **THEN** bar displays `5/15`

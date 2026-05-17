## MODIFIED Requirements

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
- **WHEN** explicit probe mode is enabled and all models in a provider group have completed probing
- **THEN** the group SHALL be shown with format: `ProviderName [████░░░░] 12/15` followed by model list
- **AND** the progress bar shows 100% filled when every model in that provider has final probe state
- **AND** models SHALL show distinct diagnostic indicators for `success`, `warning`, and `error`

#### Scenario: Race condition safety
- **WHEN** optional probe events arrive before provider map is initialized
- **THEN** those events SHALL be queued and processed once initialization completes
- **AND** no events SHALL be silently dropped
- **AND** queued events SHALL update the seeded model list rather than creating duplicate model entries

### Requirement: Display model status with visual indicators
The system SHALL show catalog and optional probe health using visual indicators for `available`, `unsupported`, `preview`, `pending`, `success`, `warning`, and `error`.

#### Scenario: Catalog available model
- **WHEN** a model is compatible with the proxy chat path
- **THEN** model is displayed as `available`
- **AND** the terminal indicator uses success styling

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

## ADDED Requirements

### Requirement: Settings dialog fits content
The settings dialog SHALL size itself so all controls and action buttons are fully visible on macOS.

#### Scenario: Dialog opens with default settings
- **WHEN** the user opens the settings dialog
- **THEN** the save/apply button is fully visible without clipping

#### Scenario: Dialog includes overlay lock settings
- **WHEN** overlay lock duration fields are present
- **THEN** the dialog expands or allows vertical resizing so the action button remains fully visible

### Requirement: Settings dialog preserves existing config fields
The settings dialog SHALL preserve existing config fields that it does not edit directly.

#### Scenario: Calendar cache fields exist
- **WHEN** the user saves settings after calendar fields or runtime state exist in the config
- **THEN** those fields are preserved unless explicitly changed by the dialog

## ADDED Requirements

### Requirement: Open config file in system default editor

The system SHALL open the config file (`~/.config/startwatch/config.json`) in the user's system default editor when the "Open Config…" menu item (⌘,) is clicked. The file path MUST be passed to `NSWorkspace.shared.open()` to leverage system file associations.

#### Scenario: User clicks "Open Config…" menu item
- **WHEN** user clicks "Open Config…" (⌘,) in the menu bar
- **THEN** the config file opens in the system default editor for JSON files (or generic text editor if no specific JSON handler is configured)

#### Scenario: Config file exists at expected location
- **WHEN** "Open Config…" is invoked
- **THEN** the system attempts to open the file at `~/.config/startwatch/config.json`
- **THEN** if the file exists, it opens in the default editor

#### Scenario: Default editor is unavailable
- **WHEN** "Open Config…" is invoked and no default editor is registered for JSON
- **THEN** NSWorkspace delegates to system default behavior (typically shows error or opens in TextEdit as fallback)

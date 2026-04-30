## Why

The built-in config editor (NSPanel with NSTextView) lacks syntax highlighting, proper undo, and basic editor conveniences. Users should edit config in their preferred system editor (TextEdit, VSCode, etc.) instead. This removes UI burden and lets the system default editor handle editing.

## What Changes

- Remove `ConfigEditorWindow.swift` (built-in NSPanel editor, 89 lines)
- Update `MenuAgentDelegate.swift`: replace `configEditor.show()` with `NSWorkspace.shared.open(ConfigManager.configURL)` when "Open Config…" (⌘,) is clicked
- Config file path (`~/.config/startwatch/config.json`) stays unchanged; NSWorkspace opens it in system default app for JSON

## Capabilities

### New Capabilities
- `config-default-editor`: Open config file in system default editor via NSWorkspace instead of built-in UI

### Modified Capabilities
<!-- None - this is a clean removal of built-in editor, not a behavior change to existing specs -->

## Impact

- **Affected files**: `MenuAgentDelegate.swift`, `ConfigEditorWindow.swift`
- **Removed code**: 89-line `ConfigEditorWindow` class and related imports
- **No API changes**: Menu item "Open Config…" (⌘,) remains; handler now delegates to NSWorkspace
- **Test impact**: No new functionality to test; existing "config editing" path now relies on system editor (no unit test coverage needed for NSWorkspace)

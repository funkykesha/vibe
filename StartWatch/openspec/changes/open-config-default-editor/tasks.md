## 1. Code Changes

- [x] 1.1 Remove `Sources/StartWatch/MenuAgent/ConfigEditorWindow.swift` (89-line file)
- [x] 1.2 Update `Sources/StartWatch/MenuAgent/MenuAgentDelegate.swift`: remove `private var configEditor = ConfigEditorWindow()` (line 8)
- [x] 1.3 Update `Sources/StartWatch/MenuAgent/MenuAgentDelegate.swift`: replace `menuBar.onOpenConfig` closure (lines 33-35) with `menuBar.onOpenConfig = { NSWorkspace.shared.open(ConfigManager.configURL) }`
- [x] 1.4 Remove unused imports from MenuAgentDelegate.swift if any (e.g., if ConfigEditorWindow was the only reason to import anything)

## 2. Build & Test

- [x] 2.1 Run `swift build` — verify no errors and no references to ConfigEditorWindow
- [x] 2.2 Run `swift test` — verify 19/19 tests pass
- [x] 2.3 Manual test: run MenuAgent, click "Open Config…" (⌘,), verify config file opens in system default editor

## 3. Verification

- [x] 3.1 Confirm config file path is unchanged (`~/.config/startwatch/config.json`)
- [x] 3.2 Verify no unintended deletions (review git diff before final commit)
- [x] 3.3 Check that menu item "Open Config…" still appears in menu bar

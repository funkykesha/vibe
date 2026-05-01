## Context

Currently, "Open Config…" (⌘,) launches a built-in NSPanel with an NSTextView, rendering YAML/JSON with no syntax highlighting. The config file lives at `~/.config/startwatch/config.json`. Users have system-wide editor preferences and tools (VSCode, TextEdit, etc.) that are better suited for this task.

## Goals / Non-Goals

**Goals:**
- Delegate config editing to user's system default editor
- Remove UI burden and maintenance of ConfigEditorWindow
- Preserve config file location and format

**Non-Goals:**
- File watching or auto-reload when config changes externally
- Custom error handling or recovery if editor fails to open
- Integration with specific editors (VSCode, Sublime, etc.)

## Decisions

**Decision 1: Use NSWorkspace.shared.open() instead of custom NSPanel**
- **Rationale**: NSWorkspace respects system-wide file associations. The OS selects the default app for `.json` files, typically TextEdit or user's chosen editor. No custom UI maintenance.
- **Alternative (rejected)**: Build a better NSPanel editor with syntax highlighting. Rejected because: out of scope for this project, duplicates editor functionality, adds dependency/maintenance burden.

**Decision 2: Delete ConfigEditorWindow.swift entirely**
- **Rationale**: No longer needed. Removing dead code reduces surface area and avoids future confusion about two editing paths.
- **Alternative (rejected)**: Keep it as fallback. Rejected because no use case; NSWorkspace is sufficient.

**Decision 3: Update MenuAgentDelegate closure in-place, no factory pattern**
- **Rationale**: Single caller (`MenuBarController.onOpenConfig`), single responsibility. Direct closure avoids over-engineering.

## Risks / Trade-offs

**Risk: Editor not available or fails silently**
- **Mitigation**: NSWorkspace handles missing associations gracefully (shows system default behavior or error dialog). No need for custom error handling.

**Risk: Config syntax errors not caught by in-app validation**
- **Mitigation**: Acceptable. Config is user's responsibility to write correctly. If errors exist, app fails at load time with clear error message (existing ConfigManager validation).

**Trade-off: No "Save" button or confirmation**
- **Mitigation**: User explicitly closes editor when done. Standard editor behavior; no special affordance needed.

## Migration Plan

1. Remove ConfigEditorWindow.swift
2. Update MenuAgentDelegate.swift (remove property, update closure)
3. Rebuild and test that "Open Config…" opens file in default editor
4. Verify swift build and swift test pass

No rollback needed; change is additive (only removes code).

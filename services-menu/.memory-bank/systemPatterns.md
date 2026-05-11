# System Patterns

## Architecture Overview
Single-file Python macOS menu bar app. `rumps.App` owns the menu lifecycle, while AppKit is used for the Add Config form and standard edit menu. Pure helper functions handle validation, plist generation, command resolution, service discovery, and status lookup.

## Tech Stack

| Layer | Technology | Version | Rationale |
|-------|------------|---------|-----------|
| App runtime | Python | 3.13 via Miniforge in rebuild script | Existing local runtime for py2app packaging |
| Menu bar UI | rumps | local dependency | Minimal macOS menu bar app framework |
| Native UI | AppKit via PyObjC | local dependency | Needed for custom form and text editing behavior |
| Packaging | py2app | setup-time dependency | Builds `.app` bundle |
| Service control | launchctl | macOS builtin | Native LaunchAgent status and restart control |

## Key Design Patterns

### Pure helpers around OS behavior
- **Where**: `validate_service_name`, `build_launch_agent_config`, `resolve_command_with_which`, `discover_service_labels`.
- **Why**: Keeps validation and plist behavior testable without launching the UI.

### LaunchAgent namespace filtering
- **Where**: `discover_service_labels`.
- **Why**: Only `com.agaibadulin.*` user agents are managed, and ServicesMenu's own label is excluded.

### AppKit bridge for focused UI gaps
- **Where**: `AddConfigWindowController`, `ensure_standard_edit_menu`.
- **Why**: rumps handles the menu, AppKit handles form fields and standard edit actions.

## Directory Structure
- `app.py` - application, helpers, UI controller, menu refresh.
- `setup.py` - py2app config, bundle plist, iconfile, libffi lookup.
- `rebuild.sh` - local rebuild/install/autostart script.
- `test_app.py` - unittest coverage for helper behavior.
- `assets/` - generated app icon PNG, `.icns`, and iconset.
- `openspec/` - change specs and archived design notes.

## Error Handling Strategy
- User input errors raise `ValidationError` and surface through `rumps.alert`.
- Malformed or unreadable LaunchAgent plists are skipped during discovery.
- Existing plist paths are not overwritten silently.
- `Which` keeps field value unchanged on lookup failure.

---
Updated on architectural decisions or tech stack changes.

## 1. Service Discovery

- [x] 1.1 Add a discovery function that scans `~/Library/LaunchAgents/com.agaibadulin.*.plist`, parses each plist with `plistlib`, and returns unique labels from valid `Label` fields.
- [x] 1.2 Exclude ServicesMenu's own LaunchAgent label from the discovered service list.
- [x] 1.3 Sort discovered labels for stable menu order while preserving status/restart behavior by label.
- [x] 1.4 Skip unreadable or malformed plist files without failing the full menu refresh.

## 2. Menu Integration

- [x] 2.1 Replace the static `SERVICES` source in `refresh_menu` with the discovered service list.
- [x] 2.2 Refresh the menu immediately after successful Add Config creation.
- [x] 2.3 Keep existing Add Config, separator, and Quit menu items stable.

## 3. Autostart Config

- [x] 3.1 Update the rebuild/install flow so `ServicesMenu.app` is installed at `/Applications/ServicesMenu.app`.
- [x] 3.2 Add or update ServicesMenu LaunchAgent config generation so `ProgramArguments` launch `/Applications/ServicesMenu.app`.
- [x] 3.3 Remove references to `/Users/agaibadulin/Desktop/projects/vibe/services_menu.py` from the ServicesMenu autostart path.
- [x] 3.4 Document or include the launchctl unload/load step needed to replace an already loaded stale LaunchAgent.

## 4. Verification

- [x] 4.1 Add tests for discovery from valid matching plist files.
- [x] 4.2 Add tests for ignoring non-matching, malformed, duplicate-label, and ServicesMenu self plist files.
- [x] 4.3 Add tests or assertions for ServicesMenu autostart plist arguments.
- [x] 4.4 Run the project test suite or equivalent syntax checks.
- [x] 4.5 Manually verify that an existing `com.agaibadulin.WorkGuard.plist` appears in the menu after refresh.

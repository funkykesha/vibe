## Why

Created LaunchAgent plist files do not appear in the menu because the app renders a hard-coded service list instead of reading the user's LaunchAgents directory. The installed autostart plist for ServicesMenu also points at a removed script path, so login startup can fail even when the packaged app exists.

## What Changes

- Replace the hard-coded menu service source with dynamic discovery of `com.agaibadulin.*.plist` files in `~/Library/LaunchAgents`.
- Exclude ServicesMenu's own LaunchAgent from the managed service list so the app does not offer to restart itself from the service menu.
- Keep service status and restart actions based on each plist's `Label`.
- Refresh the menu after creating a new LaunchAgent config so newly created services appear without relaunching the app.
- Fix the ServicesMenu install/autostart flow so the app bundle is installed at `/Applications/ServicesMenu.app`.
- Fix the ServicesMenu LaunchAgent template/installed config to launch `/Applications/ServicesMenu.app` instead of the removed `services_menu.py` script.

## Capabilities

### New Capabilities

- `launch-agent-menu-discovery`: the menu discovers manageable LaunchAgent services from the user's LaunchAgents directory.
- `services-menu-autostart`: ServicesMenu starts at login using the packaged application path.

### Modified Capabilities

None.

## Impact

- Affects `app.py` menu construction and LaunchAgent plist reading.
- Affects tests covering service discovery, menu refresh behavior, and exclusion rules.
- Affects ServicesMenu app installation path and LaunchAgent configuration path.
- Uses existing plist parsing via Python standard library; no new runtime dependency.

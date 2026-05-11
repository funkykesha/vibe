## Context

ServicesMenu currently creates LaunchAgent plist files but renders menu items from a static `SERVICES` list. This disconnect means a successfully created plist is invisible until code is edited and the app is rebuilt. There is also an installed ServicesMenu LaunchAgent that still points to a removed script path instead of the packaged app.

## Goals / Non-Goals

**Goals:**

- Make the menu reflect LaunchAgent plist files that already exist under `~/Library/LaunchAgents`.
- Make newly created `com.agaibadulin.*` configs appear after the next menu refresh without an app restart.
- Keep restart/status behavior keyed by the actual plist `Label`.
- Ensure the packaged ServicesMenu app is installed in `/Applications` and login autostart launches that bundle.

**Non-Goals:**

- Managing non-`com.agaibadulin.*` LaunchAgents.
- Editing, deleting, loading, or unloading LaunchAgent configs.
- Replacing rumps/AppKit UI.
- Changing WorkGuard behavior beyond showing it when its plist is discoverable.

## Decisions

1. Discover services from plist files matching `~/Library/LaunchAgents/com.agaibadulin.*.plist`.

   Rationale: the file naming convention already exists and limits the managed surface to this user's services. Alternative considered: use `launchctl list` as the source. That misses unloaded configs and does not provide plist paths for validation.

2. Read the `Label` key from each plist and use it for status and restart commands.

   Rationale: `launchctl` operates on labels, and the plist label is the source of truth. Alternative considered: derive the label from the filename. That can show stale or incorrect service identifiers when filename and payload differ.

3. Exclude ServicesMenu's own LaunchAgent labels from menu discovery.

   Rationale: ServicesMenu is infrastructure for the menu, not a managed service. Restarting it from inside the managed service list can produce confusing UX. Alternative considered: include it like any other service, but that mixes app lifecycle controls with service controls.

4. Refresh discovery inside the existing timer-driven `refresh_menu` flow and immediately after successful config creation.

   Rationale: the current app already rebuilds menu items periodically. Reusing that path keeps the change small and avoids filesystem watchers.

5. Install ServicesMenu as `/Applications/ServicesMenu.app` and launch it at login through `open /Applications/ServicesMenu.app`.

   Rationale: `/Applications` is the intended stable install location for this menu app, and `open` is stable across bundle identifier churn during rebuilds. Alternative considered: `/Applications/ServicesMenu.app`, but that makes the login item user-local while the desired app install location is system Applications. Direct executable path under `Contents/MacOS` was also considered, but that is more brittle for app bundle lifecycle behavior.

## Risks / Trade-offs

- Malformed plist files can break discovery -> skip unreadable files and continue building the rest of the menu.
- Duplicate labels can create duplicate menu entries -> deduplicate by `Label` while preserving sorted display order.
- Updating `/Applications/ServicesMenu.app` can require replacing an existing app bundle -> rebuild/install flow must stop the running app before copying the new bundle.
- Existing loaded LaunchAgent config may remain stale -> include a task to update the installed config and reload the LaunchAgent.

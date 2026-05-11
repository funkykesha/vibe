# Migration Guide (refactor-v2)

## Behavior Changes

- Role routing is now launch-context based, not socket-ownership based.
- `startwatch stop` is service stop only (`startwatch stop <name>`).
- `startwatch quit` stops daemon runtime.
- `startwatch` (no args, non-bundle) routes to `status`.

## Installer Changes

- `/usr/local/bin/startwatch` is real Mach-O now.
- Menu app is always deployed to `/Applications/StartWatchMenu.app`.
- LaunchAgent runs `/usr/local/bin/startwatch daemon`.

## Removed/Deprecated Patterns

- `--no-menu` runtime branch is removed from active launch contract.
- LaunchAgent should not target bundle binary path anymore.
- Wrapper-based `/usr/local/bin/startwatch` is unsupported.

## Config Implications

- `autostart=true` with `background!=true` is not auto-converted.
- Daemon skips such autostart services and logs:
  - `autostart skipped: requires background=true`
- Doctor and menu surface this state.

## IPC Changes

- Active protocol is short-lived typed JSON request/response.
- No required persistent subscribe/event stream in PR1-6.
- No active length-prefix framing on command path.

## Operational Checklist

1. Reinstall with latest `install.sh`.
2. Verify:
   - `startwatch doctor`
3. If daemon offline:
   - `launchctl kickstart gui/$(id -u)/com.user.startwatch`
4. Confirm menu icon and service actions from app bundle process.

# Progress

## What Works
- Menu bar app starts with gear menu title.
- Service labels are discovered from matching user LaunchAgent plist files.
- ServicesMenu's own LaunchAgent label is excluded from managed services.
- Status icons are derived from `launchctl list`.
- Restart action runs `launchctl stop` and `launchctl start`.
- Add Config creates validated LaunchAgent plist files and log directories.
- `Which` resolves command names with a PATH including Homebrew.
- Rebuild script packages, installs, signs, autostarts, and opens the app.
- Custom gear-related app icon is present and connected through `setup.py`.
- Unit tests cover validation, plist payloads, discovery, autostart payload, and `Which`.

## In Progress
- [ ] Memory Bank adoption for future sessions.

## What is Left

### Must Have - P0
- [ ] Rebuild/install after icon changes if the installed app should show the new icon.

### Should Have - P1
- [ ] Decide whether generated iconset and build outputs should be ignored or tracked.
- [ ] Run unit tests after future logic edits.

### Nice to Have - P2
- [ ] Add log viewing or service detail actions if needed later.
- [ ] Add UI tests only if AppKit behavior becomes risky.

## Known Issues

| # | Description | Severity | Status |
|---|-------------|----------|--------|
| 1 | Memory Bank init script failed because `_generate_defaults` was missing | Low | Worked around with manual init |
| 2 | Repo root has many unrelated dirty files outside `services-menu` | Low | Do not touch unless asked |

## Decisions Log

| Date | Decision | Alternatives | Rationale |
|------|----------|--------------|-----------|
| 2026-05-11 | Use dynamic LaunchAgent discovery | Hard-coded service list | Created services become visible automatically |
| 2026-05-11 | Use packaged `.icns` icon | Menu emoji only | Native app bundle gets custom icon |
| 2026-05-11 | Initialize Memory Bank manually | Broken init script | Needed project-specific files without placeholders |

---
Updated when tasks are completed or new issues are discovered.

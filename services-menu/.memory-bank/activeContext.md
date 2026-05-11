# Active Context

> Updated most frequently - reflects current work state.

## Current Focus
Memory Bank was initialized after adding a custom gear-related app icon and connecting it to the py2app build.

## Recent Changes

| Date | Change | Files |
|------|--------|-------|
| 2026-05-11 | Added generated app icon source and `.icns` bundle icon | `assets/app-icon.png`, `assets/app-icon.icns`, `setup.py` |
| 2026-05-11 | Initialized Memory Bank with project-specific context | `.memory-bank/*`, `.codeassistant/rules/memory-bank-autoread.md` |

## Active Decisions

### Dynamic service source
- **Context**: Menu should reflect created LaunchAgent configs.
- **Options**: Hard-code service labels, or scan `~/Library/LaunchAgents`.
- **Chosen**: Scan `com.agaibadulin.*.plist` and read each plist `Label`.
- **Why**: Newly created services appear without code changes or relaunch.

### App icon packaging
- **Context**: User requested a gear-related app icon without text.
- **Options**: Keep menu emoji only, or add a packaged macOS `.icns`.
- **Chosen**: Keep menu title as gear and add `assets/app-icon.icns` via py2app `iconfile`.
- **Why**: Bundle gets native icon while menu bar behavior stays unchanged.

## Next Steps
- [ ] Rebuild the app with `./rebuild.sh` when ready to install the new icon.
- [ ] Run `python3 -m unittest test_app.py` after logic changes.
- [ ] Consider cleaning or ignoring generated build artifacts if they should not be tracked.

## Open Questions
- [ ] Should `.memory-bank/` be committed with the project or kept local only?
- [ ] Should the generated `.iconset` directory be kept, or only source PNG plus `.icns`?

---
Updated at the start and end of each work session.

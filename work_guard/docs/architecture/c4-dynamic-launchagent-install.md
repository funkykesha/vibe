# WorkGuard — dynamic view: planned LaunchAgent install

Status: Planned.

This view captures the contract for `install-workguard-applications-launchagent`. The intended rebuild/install flow should behave like the other desktop service installers: replace the installed app bundle, refresh macOS launch metadata, update login startup, and relaunch the app. The installed `.app` remains a launcher to the configured Conda Python and project `work_guard.py`; it is not a standalone bundled Python app.

## Diagram

```mermaid
C4Dynamic
  title Dynamic Diagram — Planned LaunchAgent install path

  Person(user, "User", "Installs WorkGuard for login startup")
  Container(setup, "rebuild.sh / reinstall step", "bash", "Stops app, replaces bundle, refreshes macOS metadata")
  Container(app, "/Applications/WorkGuard.app", "macOS bundle", "Installed launcher to conda python + work_guard.py")
  ContainerDb(plist, "User LaunchAgent plist", "launchd XML", "~/Library/LaunchAgents/com.agaibadulin.workguard.plist")
  System_Ext(ls, "LaunchServices", "macOS app registration database")
  System_Ext(launchd, "launchd", "macOS user agent manager")
  Container(py, "Python core", "Conda Python 3.11", "Runs work_guard.py")
  ContainerDb(store, "Local store", "JSON + lock file", "~/.config/work_guard")

  Rel(user, setup, "1. Runs rebuild/install")
  Rel(setup, app, "2. Replaces, signs, relaunches", "cp / codesign / open")
  Rel(setup, ls, "3. Refreshes registration", "lsregister")
  Rel(setup, plist, "4. Writes ProgramArguments", "/usr/bin/open /Applications/WorkGuard.app")
  Rel(setup, launchd, "5. Reloads agent", "launchctl bootout/bootstrap")
  Rel(launchd, app, "6. Opens at login")
  Rel(app, py, "7. Execs configured python and script")
  Rel(py, store, "8. Acquires lock, reads config, writes logs")

  UpdateRelStyle(setup, app, $textColor="#1565c0", $offsetY="-12")
  UpdateRelStyle(launchd, app, $textColor="#1565c0", $offsetY="-12")
```

## Planned contract

| Concern | Direction |
|---------|-----------|
| Launch target | LaunchAgent runs `/usr/bin/open /Applications/WorkGuard.app`; the app launcher then execs Conda `python3 work_guard.py`. |
| Manual launch | `/Applications/WorkGuard.app` becomes the supported GUI target; direct terminal launch remains for debugging. |
| Bundle freshness | Reinstall stops WorkGuard, replaces `/Applications/WorkGuard.app`, refreshes LaunchServices, signs/registers, and relaunches. |
| Duplicate protection | Existing `fcntl` lock remains authoritative across installed app launches and direct debug launches. Project-local `.app` is not a supported launch target. |
| Stop/uninstall | `scripts/stop_workguard.sh` must remain compatible with `com.agaibadulin.workguard.plist` and the installed app path. |
| Ownership | Per-user only: `~/Library/LaunchAgents` and `gui/<uid>`, no system daemon. |

## Open questions before implementation

- Exact LaunchServices refresh command sequence and failure handling.
- Resolved: bundle templates and install-time assets live under `packaging/`.

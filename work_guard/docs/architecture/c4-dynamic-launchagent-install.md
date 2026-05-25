# WorkGuard — dynamic view: LaunchAgent install

Status: Current.

This view captures the current contract implemented by the archived
`install-workguard-applications-launchagent` change. The rebuild/install flow
replaces the installed app bundle, refreshes macOS launch metadata, updates login
startup, and relaunches the app. The installed `.app` remains a launcher to the
configured Conda Python and project `work_guard.py`; it is not a standalone
bundled Python app.

## Diagram

```mermaid
C4Dynamic
  title Dynamic Diagram — LaunchAgent install path

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

## Current contract

| Concern | Direction |
|---------|-----------|
| Launch target | LaunchAgent runs `/usr/bin/open /Applications/WorkGuard.app`; the app launcher then execs Conda `python3 work_guard.py`. |
| Manual launch | `/Applications/WorkGuard.app` is the supported GUI target; direct terminal launch remains for debugging. |
| Bundle freshness | Reinstall stops WorkGuard, replaces `/Applications/WorkGuard.app`, refreshes LaunchServices, signs/registers, and relaunches. |
| Duplicate protection | Existing `fcntl` lock remains authoritative across installed app launches and direct debug launches. Project-local `.app` is not a supported launch target. |
| Stop/uninstall | `scripts/stop_workguard.sh` must remain compatible with `com.agaibadulin.workguard.plist` and the installed app path. |
| Ownership | Per-user only: `~/Library/LaunchAgents` and `gui/<uid>`, no system daemon. |

## Resolved implementation details

- LaunchServices refresh uses app unregister/register rather than a global
  database kill.
- Bundle templates and install-time assets live under `packaging/`.
- `setup.sh` is obsolete and exits with a hard error pointing to `bash
  rebuild.sh`.

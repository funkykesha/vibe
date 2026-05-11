# WorkGuard — deployment view (C4 Level 4, Current)

WorkGuard is desktop-only: one user session, one machine, no server tier.
Current contract centers on the installed app at `/Applications/WorkGuard.app`.

## Diagram

```mermaid
C4Deployment
  title Deployment — WorkGuard on macOS

  Deployment_Node(mac, "User Mac", "macOS (Apple Silicon or Intel)") {
    Deployment_Node(user_session, "User session", "GUI login") {
      Container(app_bundle, "/Applications/WorkGuard.app", "macOS bundle", "Installed GUI launcher; MacOS/WorkGuard → exec python")
      Container(launch_agent, "Planned user LaunchAgent", "launchd plist", "Login startup; opens /Applications/WorkGuard.app")
    }
    Deployment_Node(conda, "Conda base", "miniforge / miniconda") {
      Container(py_rt, "workguard env", "Python 3.11", "rumps, PyObjC, pynput, tkinter")
    }
    Deployment_Node(home, "User home", "~") {
      ContainerDb(cfg, "~/.config/work_guard", "JSON + logs", "config, lock, IPC, work_guard.log")
    }
  }

  Rel(app_bundle, py_rt, "exec", "Absolute path in generated launcher")
  Rel(launch_agent, app_bundle, "opens at login", "ProgramArguments open app")
  Rel(py_rt, cfg, "File I/O", "read/write on same volume")
```

## Build and run paths

- **Public entrypoint:** `bash rebuild.sh`.
- **Run:** user opens `/Applications/WorkGuard.app`.
- **Login startup:** `~/Library/LaunchAgents/com.agaibadulin.workguard.plist` opens `/Applications/WorkGuard.app` with `RunAtLoad=true` and `KeepAlive=false`.
- **Debug only:** `conda run -n workguard python3 work_guard.py`.
- **Single instance:** `~/.config/work_guard/work_guard.lock` (fcntl) prevents duplicate Python cores.

## Not shown

- **CI/CD or app notarization** — not part of the current repository flow; distribution is local build.
- **Project-local `.app`** — not part of the supported launch contract.

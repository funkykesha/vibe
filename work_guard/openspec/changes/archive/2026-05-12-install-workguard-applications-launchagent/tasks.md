
## 1. Packaging Foundation

- [x] 1.1 Create `packaging/` and move WorkGuard app bundle templates/assets into packaging-only ownership.
- [x] 1.2 Update packaging templates so the installed app uses `CFBundleIdentifier=com.agaibadulin.workguard`.
- [x] 1.3 Ensure no documentation or rebuild output presents a repo-local `.app` as a supported launch target.

## 2. Shared Conda Discovery

- [x] 2.1 Extract conda candidate discovery from `setup.sh` into `scripts/lib/conda_discovery.sh`.
- [x] 2.2 Make the shared discovery utility return a usable conda executable or fail with a clear miniforge/install message.
- [x] 2.3 Source the shared discovery utility from the new rebuild flow without reading or executing `setup.sh`.

## 3. Rebuild Entry Point

- [x] 3.1 Create root-level `rebuild.sh` as the only supported public install/rebuild command.
- [x] 3.2 Resolve project root from the `rebuild.sh` location and resolve `work_guard.py` relative to that root.
- [x] 3.3 Create or reuse the `workguard` conda environment and resolve the active interpreter with `conda run -n workguard which python3`.
- [x] 3.4 Install Python dependencies from `requirements.txt` through the `workguard` environment during rebuild.
- [x] 3.5 Generate the installed app launcher from `packaging/` templates using the resolved interpreter path and source-root-relative `work_guard.py` path.
- [x] 3.6 Build the optional Swift menu binary when `swiftc` and `WorkGuardMenu/main.swift` are available; otherwise print a clear warning and preserve fallback behavior.

## 4. Stop, Replace, And Register App

- [x] 4.1 Call `scripts/stop_workguard.sh` from `rebuild.sh` before replacing app or LaunchAgent state.
- [x] 4.2 Abort `rebuild.sh` on any non-zero `scripts/stop_workguard.sh` exit before touching `/Applications/WorkGuard.app` or the LaunchAgent plist.
- [x] 4.3 Unregister the previous `/Applications/WorkGuard.app` with `lsregister -u` when it exists.
- [x] 4.4 Replace `/Applications/WorkGuard.app` from generated packaging output and fail clearly if `/Applications` cannot be written.
- [x] 4.5 Sign `/Applications/WorkGuard.app` ad-hoc with `codesign --force --deep --sign -`.
- [x] 4.6 Refresh LaunchServices: force-register the new app with `lsregister -f /Applications/WorkGuard.app` (do not use `lsregister -kill`; removed on recent macOS).

## 5. LaunchAgent Install

- [x] 5.1 Generate `~/Library/LaunchAgents/com.agaibadulin.workguard.plist` with label `com.agaibadulin.workguard`.
- [x] 5.2 Set LaunchAgent `ProgramArguments` exactly to `/usr/bin/open` and `/Applications/WorkGuard.app`.
- [x] 5.3 Set LaunchAgent `RunAtLoad=true` and `KeepAlive=false`.
- [x] 5.4 Reload the LaunchAgent with `launchctl bootout gui/$(id -u) <plist> || true` followed by `launchctl bootstrap gui/$(id -u) <plist>`.

## 6. App Relaunch

- [x] 6.1 Launch `/Applications/WorkGuard.app` after app registration and LaunchAgent reload.
- [x] 6.2 Confirm rebuild output reports `/Applications/WorkGuard.app` as the normal GUI target.

## 7. Legacy Entry Point And Docs

- [x] 7.1 Replace `setup.sh` content with a hard error that exits non-zero and directs the operator to `bash rebuild.sh`.
- [x] 7.2 Update `README.md` so install and normal launch use `bash rebuild.sh` and `/Applications/WorkGuard.app`.
- [x] 7.3 Update architecture docs to reflect `rebuild.sh`, packaging-only assets, stable bundle id, and user-domain LaunchAgent behavior.
- [x] 7.4 Keep direct `conda run -n workguard python3 work_guard.py` documentation only under debug/diagnostics.
- [x] 7.5 Keep `ActivitySignals` documentation scoped to future local/coarse boundary only; do not add collectors, ingestion, export, or outbound telemetry behavior.

## 8. Verification

- [x] 8.1 Implement disk-state verification commands for `/Applications/WorkGuard.app`, executable launcher, stable bundle id, and `codesign --verify --deep --strict`.
- [x] 8.2 Implement LaunchAgent verification commands for plist path, label, ProgramArguments (`/usr/bin/open`, `/Applications/WorkGuard.app`), RunAtLoad, KeepAlive, and `launchctl print gui/$(id -u)/com.agaibadulin.workguard`.
- [x] 8.3 Verify runtime startup writes `~/.config/work_guard/work_guard.lock` with the running process id and appends a fresh startup entry to `~/.config/work_guard/work_guard.log`.
- [x] 8.4 Verify opening `/Applications/WorkGuard.app` while WorkGuard is already running leaves the original lock pid in place and only one active `work_guard.py` core process.
- [x] 8.5 Verify direct debug Python launch while the installed app is running leaves the original lock pid in place and only one active `work_guard.py` core process.
- [x] 8.6 Verify `bash setup.sh` exits non-zero and points to `bash rebuild.sh`.
- [x] 8.7 Verify rebuild/install/startup paths do not add telemetry, diagnostics upload, data export, ActivitySignals collectors, ActivitySignals ingestion, or ActivitySignals export behavior.

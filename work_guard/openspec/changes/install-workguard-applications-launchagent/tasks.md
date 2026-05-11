## 1. Packaging Foundation

- [ ] 1.1 Create `packaging/` and move WorkGuard app bundle templates/assets into packaging-only ownership.
- [ ] 1.2 Update packaging templates so the installed app uses `CFBundleIdentifier=com.agaibadulin.workguard`.
- [ ] 1.3 Ensure no documentation or rebuild output presents a repo-local `.app` as a supported launch target.

## 2. Shared Conda Discovery

- [ ] 2.1 Extract conda candidate discovery from `setup.sh` into `scripts/lib/conda_discovery.sh`.
- [ ] 2.2 Make the shared discovery utility return a usable conda executable or fail with a clear miniforge/install message.
- [ ] 2.3 Source the shared discovery utility from the new rebuild flow without reading or executing `setup.sh`.

## 3. Rebuild Entry Point

- [ ] 3.1 Create root-level `rebuild.sh` as the only supported public install/rebuild command.
- [ ] 3.2 Resolve project root from the `rebuild.sh` location and resolve `work_guard.py` relative to that root.
- [ ] 3.3 Create or reuse the `workguard` conda environment and resolve the active interpreter with `conda run -n workguard which python3`.
- [ ] 3.4 Install Python dependencies from `requirements.txt` through the `workguard` environment during rebuild.
- [ ] 3.5 Generate the installed app launcher from `packaging/` templates using the resolved interpreter path and source-root-relative `work_guard.py` path.
- [ ] 3.6 Build the optional Swift menu binary when `swiftc` and `WorkGuardMenu/main.swift` are available; otherwise print a clear warning and preserve fallback behavior.

## 4. Stop, Replace, And Register App

- [ ] 4.1 Call `scripts/stop_workguard.sh` from `rebuild.sh` before replacing app or LaunchAgent state.
- [ ] 4.2 Abort `rebuild.sh` on any non-zero `scripts/stop_workguard.sh` exit before touching `/Applications/WorkGuard.app` or the LaunchAgent plist.
- [ ] 4.3 Unregister the previous `/Applications/WorkGuard.app` with `lsregister -u` when it exists.
- [ ] 4.4 Replace `/Applications/WorkGuard.app` from generated packaging output and fail clearly if `/Applications` cannot be written.
- [ ] 4.5 Sign `/Applications/WorkGuard.app` ad-hoc with `codesign --force --deep --sign -`.
- [ ] 4.6 Refresh LaunchServices with `lsregister -kill -r -domain local -domain user` and register the new app with `lsregister -f /Applications/WorkGuard.app`.

## 5. LaunchAgent Install

- [ ] 5.1 Generate `~/Library/LaunchAgents/com.agaibadulin.workguard.plist` with label `com.agaibadulin.workguard`.
- [ ] 5.2 Set LaunchAgent `ProgramArguments` exactly to `open` and `/Applications/WorkGuard.app`.
- [ ] 5.3 Set LaunchAgent `RunAtLoad=true` and `KeepAlive=false`.
- [ ] 5.4 Reload the LaunchAgent with `launchctl bootout gui/$(id -u) <plist> || true` followed by `launchctl bootstrap gui/$(id -u) <plist>`.

## 6. App Relaunch

- [ ] 6.1 Launch `/Applications/WorkGuard.app` after app registration and LaunchAgent reload.
- [ ] 6.2 Confirm rebuild output reports `/Applications/WorkGuard.app` as the normal GUI target.

## 7. Legacy Entry Point And Docs

- [ ] 7.1 Replace `setup.sh` content with a hard error that exits non-zero and directs the operator to `bash rebuild.sh`.
- [ ] 7.2 Update `README.md` so install and normal launch use `bash rebuild.sh` and `/Applications/WorkGuard.app`.
- [ ] 7.3 Update architecture docs to reflect `rebuild.sh`, packaging-only assets, stable bundle id, and user-domain LaunchAgent behavior.
- [ ] 7.4 Keep direct `conda run -n workguard python3 work_guard.py` documentation only under debug/diagnostics.
- [ ] 7.5 Keep `ActivitySignals` documentation scoped to future local/coarse boundary only; do not add collectors, ingestion, export, or outbound telemetry behavior.

## 8. Verification

- [ ] 8.1 Implement disk-state verification commands for `/Applications/WorkGuard.app`, executable launcher, stable bundle id, and `codesign --verify --deep --strict`.
- [ ] 8.2 Implement LaunchAgent verification commands for plist path, label, ProgramArguments, RunAtLoad, KeepAlive, and `launchctl print gui/$(id -u)/com.agaibadulin.workguard`.
- [ ] 8.3 Verify runtime startup writes `~/.config/work_guard/work_guard.lock` with the running process id and appends a fresh startup entry to `~/.config/work_guard/work_guard.log`.
- [ ] 8.4 Verify opening `/Applications/WorkGuard.app` while WorkGuard is already running leaves the original lock pid in place and only one active `work_guard.py` core process.
- [ ] 8.5 Verify direct debug Python launch while the installed app is running leaves the original lock pid in place and only one active `work_guard.py` core process.
- [ ] 8.6 Verify `bash setup.sh` exits non-zero and points to `bash rebuild.sh`.
- [ ] 8.7 Verify rebuild/install/startup paths do not add telemetry, diagnostics upload, data export, ActivitySignals collectors, ActivitySignals ingestion, or ActivitySignals export behavior.

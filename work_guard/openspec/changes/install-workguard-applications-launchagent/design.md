## Context

WorkGuard currently still has the legacy `setup.sh` path that builds a project-local `WorkGuard.app` launcher. The updated proposal makes that path obsolete and defines a new public contract: operators run `bash rebuild.sh`, the runnable GUI target is `/Applications/WorkGuard.app`, and login startup is handled by `~/Library/LaunchAgents/com.agaibadulin.workguard.plist`.

The installed app remains a launcher to the project Python entrypoint and conda environment. This change is not a py2app or standalone packaging effort. It is a deterministic local reinstall workflow for a single-user macOS menu utility.

## Goals / Non-Goals

**Goals:**

- **P0 contract:** Provide one public rebuild/install command: `bash rebuild.sh`.
- **P0 contract:** Install or replace `/Applications/WorkGuard.app` as the only supported GUI launch target.
- **P0 contract:** Generate and reload one LaunchAgent: `com.agaibadulin.workguard`, opening `/Applications/WorkGuard.app` with `RunAtLoad=true` and `KeepAlive=false`.
- **P0 contract:** Keep `CFBundleIdentifier` stable as `com.agaibadulin.workguard`.
- **P1 implementation hygiene:** Move app bundle templates and install-time assets under packaging-only ownership so repo-local bundle files are not treated as runnable app targets.
- **Invariant:** Keep direct Python launch available only for debug and diagnostics.
- **Invariant:** Preserve local-only privacy behavior and avoid introducing outbound telemetry or ActivitySignals collectors.

**Non-Goals:**

- Preserve `setup.sh` as a wrapper, fallback, or compatibility entrypoint.
- Support launching from a repo-local `.app`.
- Bundle Python, conda, or dependencies into a standalone `.app`.
- Add app notarization, distribution packaging, or system-wide daemon installation.
- Add ActivitySignals collection, export, ingestion, or network behavior.

## Decisions

1. Use `rebuild.sh` as the sole public operator entrypoint.

   Rationale: a single command prevents drift between environment setup, app bundle generation, LaunchServices refresh, LaunchAgent replacement, and relaunch. The legacy `setup.sh` contract is too narrow because it produces a local launcher and leaves autostart behavior out of band.

   Alternative considered: keep `setup.sh` and add a separate reinstall script. That preserves ambiguity around which command is canonical and contradicts the proposal's one-entrypoint contract.

2. Keep the installed `.app` as a launcher to conda Python and `work_guard.py`.

   Rationale: WorkGuard already depends on local conda setup, PyObjC behavior, Swift menu fallback, logs, config, and source-relative assets. Reusing the existing launcher model keeps scope small and avoids a standalone packaging project.

   Alternative considered: py2app-style standalone bundle. That would add packaging and dependency complexity unrelated to the requested reinstall flow.

3. Install only to `/Applications/WorkGuard.app`.

   Rationale: a stable Applications path gives LaunchAgent, manual launch, Accessibility permissions, and operator docs one shared target. Repo-local `.app` files become packaging inputs only.

   Alternative considered: support both `/Applications/WorkGuard.app` and a repo-local app. That creates duplicate permission targets and makes launch behavior depend on which copy the user opens.

4. Use a stable bundle identifier: `com.agaibadulin.workguard`.

   Rationale: the app identity should be stable for macOS permissions, notification identity, LaunchServices, and user expectations. Bundle ID churn hides stale-cache problems instead of making the reinstall flow reliable.

   Alternative considered: timestamped bundle IDs like the ServicesMenu rebuild script. That can force LaunchServices refresh but creates unstable identity and is a bad fit for an app requiring privacy permissions.

5. Refresh LaunchServices explicitly during reinstall with `lsregister`, user domains only.

   Rationale: replacing a macOS app bundle in place can leave LaunchServices with stale metadata. The rebuild flow runs without sudo and therefore scopes `lsregister` to user-accessible domains only. The full sequence uses the system tool at `/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister`:

   - `lsregister -u /Applications/WorkGuard.app` — unregister the previous bundle when present.
   - `lsregister -kill -r -domain local -domain user` — flush stale metadata in user-accessible domains. `-domain system` is omitted because it requires root and is not needed for a single-user menu utility.
   - `lsregister -f /Applications/WorkGuard.app` — register the new bundle.

   Alternative considered: rely on `open` to discover the replaced app. That is simpler but leaves stale bundle metadata as an intermittent failure mode.

6. Generate LaunchAgent from the rebuild flow and reload it with user-domain `launchctl`.

   Rationale: the LaunchAgent payload is part of the install contract, not runtime state. Rebuild should write the plist, then run `launchctl bootout gui/<uid> <plist> || true` and `launchctl bootstrap gui/<uid> <plist>` so loaded state matches disk.

   Alternative considered: only write the plist and wait for next login. That makes verification slow and leaves stale loaded configs active.

7. Keep `KeepAlive=false`.

   Rationale: WorkGuard is a user-facing menu app. Existing single-instance locking handles duplicate launches, and automatic respawn can create confusing restart loops during debugging or stop flows.

   Alternative considered: `KeepAlive=true`. That is useful for daemons but too aggressive for this GUI app.

8. Treat `scripts/stop_workguard.sh` as the stop/unload authority.

   Rationale: it already discovers WorkGuard-like LaunchAgents, boots them out, disables labels, uses the PID lock, and kills leftover `work_guard.py` processes. Rebuild should call it instead of duplicating stop logic. If `scripts/stop_workguard.sh` exits non-zero, `rebuild.sh` must stop immediately and must not replace `/Applications/WorkGuard.app`, rewrite the LaunchAgent, or relaunch WorkGuard. A partial stop is an unsafe state for install because an old Python process can hold the lock or an old LaunchAgent can restart the app during bundle replacement.

   Alternative considered: implement separate stop logic in `rebuild.sh`. That risks divergence and misses future hardening in the stop script.

9. Keep install privacy-neutral.

   Rationale: installing, launching, and autostarting WorkGuard must not imply new outbound behavior. No data leaves the machine by default; explicit user-initiated exports are outside this change; secrets must never be exported.

   Alternative considered: add diagnostics upload or telemetry while changing install flow. That expands trust and privacy scope without being required.

10. Replace `setup.sh` with a hard error rather than preserving it.

    Rationale: the proposal explicitly removes `setup.sh` as a supported wrapper, fallback, or migration shim. Leaving it operational would keep two install entrypoints alive and reintroduce the ambiguity this change removes. The least ambiguous behavior is a short hard error that points to `bash rebuild.sh`.

    Alternative considered: delete `setup.sh`. That is clean but can produce a less helpful shell-level "file not found" for users with old muscle memory. A hard error is clearer during the transition while still keeping `setup.sh` unsupported.

11. Extract conda discovery into a shared utility sourced by both `rebuild.sh` and any remaining scripts.

    Rationale: `setup.sh` is being replaced with a hard error, so the conda candidate list it contained must not be lost. Duplicating discovery logic across scripts causes drift. A single sourced utility (e.g. `scripts/lib/conda_discovery.sh`) keeps the candidate list in one place and lets `rebuild.sh` inherit any future hardening.

    Alternative considered: hardcode the candidate list directly in `rebuild.sh`. That works initially but diverges from any other script that needs conda and makes future updates error-prone.

12. Keep dependency installation inside `rebuild.sh`.

    Rationale: `rebuild.sh` is the only supported install/rebuild entrypoint, so it must own the full local runtime preparation needed by the installed launcher. After resolving the `workguard` conda environment, it installs `requirements.txt` through that environment before generating and launching `/Applications/WorkGuard.app`.

    Alternative considered: require a separate dependency setup command before rebuild. That reintroduces multi-command install drift and leaves rebuild success dependent on undocumented prior state.

13. Preserve optional Swift menu build as part of rebuild.

    Rationale: the Swift menu binary is an existing compatibility path for menu bar behavior on macOS versions where the Python menu path is unreliable. Rebuild should compile it when `swiftc` is available and the source exists, while preserving fallback behavior when it cannot be built.

    Alternative considered: remove Swift compilation from rebuild. That would make reinstall regress existing menu behavior even though the change is intended to stabilize install/launch only.

## Risks / Trade-offs

- Existing Accessibility or Notification permissions may be tied to the old project-local app or Python process -> document `/Applications/WorkGuard.app` and Python permission checks after reinstall.
- LaunchServices can keep stale metadata after replacement -> run explicit `lsregister -u`, `lsregister -kill -r -domain local -domain user`, and `lsregister -f` steps around app replacement.
- `launchctl bootstrap` can fail if an old label remains disabled or loaded -> `stop_workguard.sh` must bootout/disable legacy labels first; rebuild must bootout the target plist before bootstrap.
- `stop_workguard.sh` can fail halfway through cleanup -> abort rebuild on non-zero exit before changing app or LaunchAgent state.
- Rebuild may require permission to write `/Applications` -> fail with a clear message if copy/removal cannot complete; do not silently fall back to a project-local app.
- Removing `setup.sh` as a supported path can break muscle memory -> replace it with a hard error that points to `bash rebuild.sh`, then update README and architecture docs.
- Stable bundle ID can expose stale-cache issues that timestamp churn masked -> solve with deterministic LaunchServices refresh rather than identity churn.
- App bundle remains source-linked to the project path -> document that moving the project requires rerunning `bash rebuild.sh`.
- Conda discovery logic was previously in `setup.sh` -> extract to `scripts/lib/conda_discovery.sh` before removing `setup.sh` content.
- Dependency installation was previously coupled to `setup.sh` -> make `rebuild.sh` install `requirements.txt` after resolving the `workguard` environment.
- Swift menu compilation can fail when Xcode Command Line Tools are unavailable -> log a clear warning and preserve the existing Python/rumps fallback behavior.

## Migration Plan

1. Extract conda discovery from `setup.sh` into `scripts/lib/conda_discovery.sh`.
2. Create `rebuild.sh` as the public install command. Source `scripts/lib/conda_discovery.sh` to discover conda, create/reuse the `workguard` environment, and resolve the active interpreter with `conda run -n workguard which python3`. Resolve the project root from the script location.
3. Move bundle templates, plist templates, icons, and packaging assets under `packaging/`.
4. Generate the installed app launcher from `packaging/` templates using the resolved interpreter path and source-root-relative `work_guard.py` path captured at rebuild time. Moving the repo invalidates the launcher and requires rerunning `bash rebuild.sh`.
5. Stop running WorkGuard through `scripts/stop_workguard.sh`; abort on any non-zero exit.
6. Replace `/Applications/WorkGuard.app`, sign it ad-hoc, refresh LaunchServices with `lsregister` (user domains only), and register the new bundle.
7. Write `~/Library/LaunchAgents/com.agaibadulin.workguard.plist`.
8. Reload the LaunchAgent in `gui/<uid>`.
9. Launch `/Applications/WorkGuard.app`.
10. Replace `setup.sh` content with a hard error that prints a message directing the operator to `bash rebuild.sh` and exits non-zero.
11. Update README and architecture docs so `bash rebuild.sh` and `/Applications/WorkGuard.app` are the supported install/run contract.

Rollback: run `scripts/stop_workguard.sh`, remove `~/Library/LaunchAgents/com.agaibadulin.workguard.plist`, remove `/Applications/WorkGuard.app`, and use direct Python only for debugging until the reinstall flow is fixed.

## Verification / Acceptance Criteria

**Disk and process state — verifiable immediately after rebuild exits:**

- `bash rebuild.sh` exits `0`.
- `/Applications/WorkGuard.app` exists and contains `Contents/MacOS/WorkGuard`.
- `/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' /Applications/WorkGuard.app/Contents/Info.plist` prints `com.agaibadulin.workguard`.
- `codesign --verify --deep --strict /Applications/WorkGuard.app` succeeds after ad-hoc signing.
- `~/Library/LaunchAgents/com.agaibadulin.workguard.plist` exists.
- Plist `ProgramArguments` are exactly `open` and `/Applications/WorkGuard.app`.
- Plist `RunAtLoad` is `true`; plist `KeepAlive` is `false`.
- `launchctl print gui/$(id -u)/com.agaibadulin.workguard` succeeds after rebuild.
- `bash setup.sh` exits non-zero with a message directing the operator to `bash rebuild.sh`.

**Runtime behavior — verifiable after the launched process starts:**

- A WorkGuard process starts from the installed app path and acquires `~/.config/work_guard/work_guard.lock`.
- `~/.config/work_guard/work_guard.log` receives a fresh startup entry.
- Opening `/Applications/WorkGuard.app` a second time does not start a second Python core; the existing single-instance lock remains authoritative.

## Open Questions

- Should the packaging directory be named `packaging/` or follow another project convention? No current packaging directory exists; `packaging/` is assumed in this document and should be confirmed at implementation start.

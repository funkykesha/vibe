## Why

WorkGuard needs one stable install and relaunch contract for macOS desktop use. Current proposal still leaves ambiguity around `setup.sh`, project-local app bundles, and mutable bundle identifiers, which creates reinstall drift and inconsistent launch behavior.

This change locks the supported operator path to one command, one installed app location, one LaunchAgent contract, and one stable bundle identity. It also documents strict local-only privacy boundaries so packaging and launch automation do not imply any outbound behavior.

## What Changes

- Define `bash rebuild.sh` as the only supported public install and rebuild entrypoint.
- Mark `setup.sh` as an obsolete path. It is not a supported wrapper, compatibility layer, or fallback entrypoint.
- Define `/Applications/WorkGuard.app` as the only supported runnable app target.
- Remove project-local `.app` bundles as supported launch targets. Any bundle templates or assets kept in the repo exist only as packaging inputs and not as runnable app locations.
- Keep bundle templates, plist templates, icons, and related assets in a dedicated packaging directory used only to build the installed app bundle and LaunchAgent payloads.
- Fix the app bundle identifier to `com.agaibadulin.workguard` with no timestamp-based churn or per-build bundle ID variation.
- Fix the LaunchAgent contract to `~/Library/LaunchAgents/com.agaibadulin.workguard.plist`, launching via `open /Applications/WorkGuard.app`, with `RunAtLoad=true` and `KeepAlive=false`.
- Limit direct Python execution to debug and diagnostics flows only. It remains available for local troubleshooting but is not a supported end-user launch path.
- Document `ActivitySignals` only as a future boundary for local, coarse-grained activity semantics. This proposal does not add collectors, ingestion, or new signal capture behavior now.
- Lock privacy behavior: no outbound data transfer by default, nothing leaves the machine without an explicit user request, and secrets never leave the machine under any request path.

## Non-Goals

- Do not preserve `setup.sh` as a wrapper or migration shim.
- Do not support launching WorkGuard from a repo-local `.app`.
- Do not make direct Python execution a first-class runtime path.
- Do not introduce `ActivitySignals` collectors or any outbound telemetry/export pipeline.

## Capabilities

### New Capabilities

- `workguard-applications-rebuild`: Operators can run `bash rebuild.sh` to rebuild and reinstall WorkGuard into `/Applications/WorkGuard.app` using the packaging-only bundle assets.
- `workguard-login-autostart`: WorkGuard can start at login from `~/Library/LaunchAgents/com.agaibadulin.workguard.plist`, which runs `open /Applications/WorkGuard.app` with `RunAtLoad=true` and `KeepAlive=false`.

### Modified Capabilities

- `workguard-local-debug-launch`: Direct Python remains available only for local debug and diagnostics, not for supported day-to-day launch or install flows.
- `workguard-privacy-boundary`: WorkGuard install and launch behavior remains local-only by default; outbound transfer requires explicit user initiation, and secrets are never exported.
- `workguard-activity-boundary`: `ActivitySignals` stays a documented future interface boundary only, scoped to local/coarse semantics without implemented collectors in this change.

## Impact

- Affects `rebuild.sh` as the sole supported public entrypoint for build, install, LaunchAgent refresh, and relaunch behavior.
- Affects packaging-specific directories and assets because runnable app templates move under packaging-only ownership rather than acting as repo-local launch targets.
- Affects LaunchAgent generation and verification because the supported plist path, launch command, and boolean flags are now fixed contract values.
- Affects documentation and operator guidance so every supported install and launch path points to `bash rebuild.sh` and `/Applications/WorkGuard.app`.
- Removes the open question about `setup.sh` versus a separate reinstall path: `setup.sh` is obsolete, and only `rebuild.sh` remains supported.

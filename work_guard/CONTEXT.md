# WorkGuard

This file is a glossary and domain-context note.
It is not agent instructions.
It is not the operational runbook.

Local macOS utility that detects after-hours work and guides the user back to
rest through menu status, notifications, and overlays.

## Language

**Supported GUI target**:
The canonical installed app identity, `/Applications/WorkGuard.app`.
_Avoid_: direct Python launch as installed target, project-local app as login target

**Project App Template**:
Source material used by rebuild/package flows to generate the installed app
bundle, not a clickable runtime app.
_Avoid_: project-local launch target, second installed app

**Packaging Directory**:
A dedicated repo folder that contains app bundle templates and install-time
assets.
_Avoid_: root-level runnable `.app`, mixed runtime/source/package assets

**Debug launch**:
Direct terminal execution of `work_guard.py` for diagnostics.
_Avoid_: treating debug launch as supported login startup

**Activity Signal**:
A local, coarse fact about current user activity that may help WorkGuard decide
status or guidance.
_Avoid_: raw user event, telemetry, clickstream

**Activity Signals Boundary**:
A documented future extension boundary for local system, browser, and app
activity signals.
_Avoid_: current collector implementation, raw event storage, external telemetry

**Sensitive Secret**:
A password, token, credential, private key, or equivalent secret material.
_Avoid_: exportable user activity, diagnostic payload, support bundle content

**Explicit User Request**:
A direct user action that asks WorkGuard to send or export non-secret data.
_Avoid_: implied consent, default telemetry, hidden sync

**Rebuild Install Flow**:
The repeatable root-level command that rebuilds WorkGuard, replaces the installed
app bundle, refreshes macOS app metadata, reloads login startup, and relaunches.
_Avoid_: separate setup script, one-off setup step, hidden autostart mutation

**Obsolete Setup Path**:
The old one-off setup workflow, no longer a supported setup, build, install, or
compatibility path.
_Avoid_: setup wrapper, secondary install command

**Login Startup Policy**:
LaunchAgent behavior that starts WorkGuard at load/login without forcing
restarts after the user quits.
_Avoid_: daemon-style keepalive, recursive autostart

**Stable App Identity**:
The installed WorkGuard bundle identity, `com.agaibadulin.workguard`, retained
across rebuilds.
_Avoid_: timestamp Bundle ID churn, permission-reset identity changes

## Relationships

- A **Supported GUI target** starts one Python core process through its launcher.
- A **Project App Template** may exist in the repo, but the user-facing app lives
  only at the **Supported GUI target**.
- A **Packaging Directory** owns **Project App Template** files so the repo root
  does not look like it contains a runnable app.
- A **Debug launch** starts the same Python core process without becoming the
  installed login-startup identity.
- An **Activity Signal** may come from macOS, browsers, or app-specific sources,
  but WorkGuard should consume it as a local coarse fact rather than raw history.
- The **Activity Signals Boundary** is documented now but not implemented as
  collectors in the install change.
- An **Explicit User Request** may allow non-secret data to leave the machine.
- A **Sensitive Secret** must not leave the machine even after an **Explicit User
  Request**.
- A **Rebuild Install Flow** produces and installs the **Supported GUI target**.
- An **Obsolete Setup Path** should be removed from user-facing docs and future
  implementation rather than preserved as a second command.
- **Login Startup Policy** uses `RunAtLoad=true` and `KeepAlive=false`.
- **Stable App Identity** is preserved by reinstalling and re-registering the app,
  not by changing Bundle ID on every rebuild.

## Example Dialogue

> **Dev:** "Should the LaunchAgent exec Python directly?"
> **Domain expert:** "No. Login startup opens the **Supported GUI target**; direct
> Python is only a **Debug launch**."

> **Dev:** "Can users launch `WorkGuard.app` from the project folder?"
> **Domain expert:** "No. The project contains a **Project App Template** only;
> the runnable app is `/Applications/WorkGuard.app`."

> **Dev:** "Where should the app template live?"
> **Domain expert:** "In a **Packaging Directory**, separate from runtime source
> files and not as a root-level runnable `.app`."

> **Dev:** "Can browser history become an **Activity Signal**?"
> **Domain expert:** "Only after it is reduced to a local coarse fact. Raw URL
> history is not an Activity Signal."

> **Dev:** "Should we add Activity Signal collectors now?"
> **Domain expert:** "No. Document the **Activity Signals Boundary** as a future
> local-only extension point and keep current code changes minimal."

> **Dev:** "If the user asks to export diagnostics, can secrets be included?"
> **Domain expert:** "No. An **Explicit User Request** can export non-secret
> diagnostics only; **Sensitive Secrets** stay local."

> **Dev:** "Should install live in a separate helper script?"
> **Domain expert:** "No. Follow ServicesMenu: use one root **Rebuild Install
> Flow** for rebuild, `/Applications` replacement, LaunchAgent reload, and
> relaunch."

> **Dev:** "Should the legacy setup script remain as a compatibility wrapper?"
> **Domain expert:** "No. Keep one visible entrypoint, `rebuild.sh`, so setup,
> rebuild, install, LaunchAgent reload, and relaunch cannot drift."

> **Dev:** "Can the legacy setup script stay as an old alias?"
> **Domain expert:** "No. It is an **Obsolete Setup Path** and should disappear
> from the supported workflow."

> **Dev:** "Should launchd keep WorkGuard alive after the user quits?"
> **Domain expert:** "No. **Login Startup Policy** starts WorkGuard at load/login
> but does not resurrect it after explicit quit."

> **Dev:** "Should rebuild change Bundle ID to force macOS cache refresh?"
> **Domain expert:** "No. Keep **Stable App Identity** and make reinstall
> unregister, replace, sign, register, and fail loudly if verification fails."

## Flagged Ambiguities

- "LaunchAgent target" was used for both `/Applications/WorkGuard.app` and
  direct Python. Resolved: installed login startup opens the **Supported GUI
  target**; direct Python remains a **Debug launch**.
- "User action data" could mean local guidance facts or exportable telemetry.
  Resolved: future behavior uses local coarse **Activity Signals**; data leaves
  the machine only after an **Explicit User Request**, and **Sensitive Secrets**
  never leave.

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

**Authorized Credential Use**:
Use of a user-configured third-party credential only as authentication to that
credential's own service endpoint for an explicitly enabled integration.
_Avoid_: credential export, telemetry consent, sending secrets to WorkGuard or
support destinations

**Local Secret Environment File**:
A gitignored local `.env` file that stores user-provided integration secrets.
_Avoid_: tracked config, shared defaults, writing secrets into `config.json`

**Todoist Interaction**:
A recent contact with Todoist through the Todoist app, the Todoist website, or a
task change observed through the explicitly enabled Todoist integration. Any
observed Todoist task change counts, regardless of who or what caused it.
_Avoid_: productivity score, task completion, generic work activity

**Todoist Non-Interaction Time**:
Work time during which no **Todoist Interaction** happened, regardless of whether
the user was active in another app or inactive at the computer.
_Avoid_: idle time only, non-work time, productivity judgment

**Morning Todoist Check**:
The first Todoist reminder evaluation that WorkGuard can perform during a work
period, for example after the user opens the laptop or WorkGuard resumes.
_Avoid_: morning grace period, waiting for the normal idle threshold

**Todoist Change Time**:
The Todoist-provided timestamp for an observed task change, such as `updated_at`
for active task changes, `completed_at` for completed tasks, or an activity event
time for deleted tasks, used to decide whether the change is still recent.
_Avoid_: poll time, time WorkGuard noticed an already-old change

**System Todoist Change**:
A Todoist-generated maintenance change that updates task metadata without a user
or collaborator changing the plan, such as automatic recurring due-date reschedule.
_Avoid_: task completion, deletion, content/priority edits, explicit user actions

**Unavailable Todoist Signal**:
A configured Todoist signal source that cannot currently report an interaction,
for example because an API call failed or browser history could not be read.
_Avoid_: implicit interaction, reminder suppression reason

**Todoist Task Snapshot**:
The latest successfully fetched local copy of active Todoist tasks used to render
the Todoist reminder dashboard.
_Avoid_: live Todoist UI, clickable task list, source of truth for editing tasks

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
restarts after the user quits. The LaunchAgent runs
`/usr/bin/open /Applications/WorkGuard.app`.
_Avoid_: daemon-style keepalive, recursive autostart

**Stable App Identity**:
The installed WorkGuard bundle identity, `com.agaibadulin.workguard`, retained
across rebuilds.
_Avoid_: timestamp Bundle ID churn, permission-reset identity changes

**Overlay Deferral**:
A user-granted delay before the next overtime overlay in the current overtime
session.
_Avoid_: schedule extension, pause, workday extension

**Overlay Deferral Cutoff**:
The final period before an overlay when the user can no longer defer that
overlay.
_Avoid_: hidden grace period, automatic postponement

**Overlay Deferral Ladder**:
A one-way sequence of allowed overlay deferrals that gets stricter as overtime
continues.
_Avoid_: unlimited postpone button, resettable deferral choice

**Deferral Period**:
The work-period window during which overlay deferral choices are consumed.
_Avoid_: calendar day, overtime session, app run, pause window

**Pending Schedule Change**:
A schedule edit saved during an active deferral period that applies only to a
future work period.
_Avoid_: immediate schedule override, current-period reset

**Pending Period Settings**:
Settings saved during an active deferral period that apply only to a future work
period.
_Avoid_: immediate current-period override, partial current-period settings

**Current Period Settings**:
The settings snapshot that governs the active deferral period until the next work
period begins.
_Avoid_: latest config, process-local settings

**Contextual Deferral Control**:
The single menu item whose label and enabled state reflect the current deferral
ladder position. Outside overtime it shows "Работаем!" (disabled). During
overtime it shows the next available deferral step or "пора отдыхать" when the
ladder is exhausted or the cutoff window is active.
_Avoid_: pause, monitoring pause, treating deferral as schedule change

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
  Request**, except for **Authorized Credential Use**.
- **Authorized Credential Use** sends a credential only to the third-party service
  endpoint that issued or accepts it, and only for an explicitly enabled
  integration.
- A **Local Secret Environment File** stores integration credentials locally and
  must be ignored by git.
- A **Todoist Interaction** can reset the Todoist reminder idle clock.
- **Todoist Non-Interaction Time** accumulates during work time when Todoist did
  not change and the Todoist app or website was not opened on the computer.
- Lunches and breaks are not modeled separately; inside the configured work window,
  **Todoist Non-Interaction Time** is wall-clock time.
- A **Morning Todoist Check** shows the reminder immediately when no **Todoist
  Interaction** has happened within the configured threshold before that check.
- API-based **Todoist Interaction** recency uses **Todoist Change Time** when the
  API provides it, so an old change noticed at laptop-open does not look fresh.
- On API cold start, active tasks with fresh `updated_at` values count as
  **Todoist Interaction**.
- A **System Todoist Change** does not count as **Todoist Interaction**.
- Completed and deleted Todoist tasks also count as **Todoist Interaction** when
  their **Todoist Change Time** is within the reminder threshold.
- Todoist task move and reorder events count as **Todoist Interaction**.
- Completed/deleted Todoist API lookback covers the configured threshold plus the
  poll interval plus a five-minute buffer.
- A running Todoist app does not count as **Todoist Interaction** unless Todoist is
  frontmost, because background presence does not prove the user saw the plan.
- A browser History visit to `todoist.com` counts as **Todoist Interaction** even
  if WorkGuard cannot prove that the tab was frontmost.
- An **Unavailable Todoist Signal** does not count as **Todoist Interaction** and
  does not suppress the Todoist reminder by itself.
- Todoist reminder enablement and Todoist API access are separate: the enabled
  flag activates app/browser monitoring, while a configured token adds the API
  signal through **Authorized Credential Use**.
- The Todoist reminder dashboard renders the latest **Todoist Task Snapshot**,
  refreshed periodically in the background when API access is configured.
- Missing **Todoist Task Snapshot** does not suppress the reminder; the overlay
  still shows the reminder message and actions without task details.
- Dismissing the Todoist reminder overlay does not count as **Todoist
  Interaction**; it only delays the next reminder by the configured cadence.
- Choosing the Todoist reminder's open-Todoist action counts immediately as
  **Todoist Interaction**, before waiting for the next monitoring tick.
- After the open-Todoist action, the next reminder is governed by the normal
  non-interaction threshold from that interaction time; repeat cadence applies to
  dismiss only.
- A **Rebuild Install Flow** produces and installs the **Supported GUI target**.
- An **Obsolete Setup Path** should be removed from user-facing docs and future
  implementation rather than preserved as a second command.
- **Login Startup Policy** uses `/usr/bin/open /Applications/WorkGuard.app`,
  `RunAtLoad=true`, and `KeepAlive=false`.
- **Stable App Identity** is preserved by reinstalling and re-registering the app,
  not by changing Bundle ID on every rebuild.
- An **Overlay Deferral** postpones the next overtime overlay without changing
  the user's configured schedule or ending the current overtime session.
- An **Overlay Deferral** adds its duration to the currently scheduled next
  overlay time, not to the time when the user clicks the control.
- An **Overlay Deferral Cutoff** prevents last-moment deferral immediately before
  an overlay is due, and applies to every **Overlay Deferral** option.
- An **Overlay Deferral Cutoff** is measured against the currently scheduled next
  overlay time, including any prior deferrals.
- An **Overlay Deferral Ladder** permits progressively smaller deferrals and ends
  after the smallest deferral is used.
- The **Overlay Deferral Ladder** starts before the first overtime overlay in a
  session.
- The **Overlay Deferral Ladder** advances only when the user chooses an
  **Overlay Deferral**, not when an overlay is shown.
- Overlay cadence and lock escalation continue after an overlay is shown; an
  **Overlay Deferral** only postpones the currently scheduled next overlay.
- A **Deferral Period** resets the **Overlay Deferral Ladder** only when the next
  work period begins, not when the current overtime session temporarily stops or
  the calendar day changes.
- **Pending Period Settings** may be saved during a **Deferral Period**, but they
  must not change the current period's enforcement behavior.
- **Current Period Settings** must persist across app restarts so restarting
  WorkGuard cannot apply **Pending Period Settings** to the current period early.
- When settings are saved as **Pending Period Settings**, the settings dialog
  tells the user they will apply in the next work period.
- **Overlay Deferral** is controlled from the menu via the **Contextual Deferral
  Control**, not from the overlay itself.
- The **Overlay Deferral Ladder** has three forced-order steps: 20 → 10 → 5 minutes.
- The **Contextual Deferral Control** label during overtime uses the next available
  step, e.g. "Отложить на 20 мин", "Отложить на 10 мин", "Отложить на 5 мин".
- When no overtime deferral is available, the **Contextual Deferral Control**
  remains visible but disabled with label "пора отдыхать".

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

> **Dev:** "Can an enabled Todoist integration send the Todoist token to
> Todoist?"
> **Domain expert:** "Yes. That is **Authorized Credential Use**: the credential is
> stored locally, not logged or exported, and sent only to Todoist's API endpoint
> as authentication for the explicitly enabled integration."

> **Dev:** "Where should the Todoist API token live?"
> **Domain expert:** "In a gitignored **Local Secret Environment File**, not in
> `config.json`."

> **Dev:** "If the user works in an IDE for two hours but never opens Todoist, did
> they interact with Todoist?"
> **Domain expert:** "No. They may be working, but there was no **Todoist
> Interaction**."

> **Dev:** "Does a background-running Todoist app count as interaction?"
> **Domain expert:** "No. Todoist must be frontmost or opened as a website visit,
> or Todoist task data must change."

> **Dev:** "Does a `todoist.com` browser History visit count if the tab may not
> have been frontmost?"
> **Domain expert:** "Yes. Browser History is a coarse signal; any recorded
> Todoist visit counts."

> **Dev:** "Does any observed Todoist task change count as interaction, including
> mobile edits, recurring updates, or shared project changes?"
> **Domain expert:** "Yes for user-visible task changes, but not for **System
> Todoist Change**."

> **Dev:** "Should inactivity at the computer suppress the Todoist reminder?"
> **Domain expert:** "No. During work time, inactivity is still **Todoist
> Non-Interaction Time** if Todoist did not change and the Todoist app or website
> was not opened."

> **Dev:** "Should lunch or breaks pause Todoist Non-Interaction Time?"
> **Domain expert:** "No. Breaks are not modeled; inside the work window the timer
> is wall-clock."

> **Dev:** "Should the start of the work day wait for the normal threshold before
> showing a Todoist reminder?"
> **Domain expert:** "No. At the first **Morning Todoist Check**, show the reminder
> immediately if there has been no **Todoist Interaction** in the current work
> period."

> **Dev:** "If Todoist changed from a phone before opening the laptop, should the
> morning overlay show?"
> **Domain expert:** "Only if that **Todoist Change Time** is older than the
> configured threshold when WorkGuard checks."

> **Dev:** "On API cold start, do active tasks with fresh `updated_at` count as
> interaction?"
> **Domain expert:** "Yes. A fresh active-task `updated_at` is **Todoist
> Interaction** even if WorkGuard has no previous snapshot."

> **Dev:** "Should automatic recurring reschedules count as Todoist Interaction?"
> **Domain expert:** "No. System-generated changes are **System Todoist Change**,
> not **Todoist Interaction**."

> **Dev:** "Do moved or reordered Todoist tasks count as interaction?"
> **Domain expert:** "Yes. Moving or reordering tasks is work with the plan."

> **Dev:** "Do completed and deleted Todoist tasks count for the same recency
> rule?"
> **Domain expert:** "Yes. Use `completed_at` for completed tasks and the Todoist
> activity event time for deleted tasks."

> **Dev:** "How far back should completed/deleted Todoist checks look?"
> **Domain expert:** "Look back `idle_threshold_min + poll_interval_min + 5 min`."

> **Dev:** "If the Todoist API call fails, should WorkGuard treat that as possible
> hidden interaction and stay quiet?"
> **Domain expert:** "No. A failed call is an **Unavailable Todoist Signal**, not a
> **Todoist Interaction**."

> **Dev:** "If the reminder is enabled but the Todoist token is empty or invalid,
> should the reminder still work?"
> **Domain expert:** "Yes. It still works from app and browser signals; the token
> only adds the API signal."

> **Dev:** "What should the reminder dashboard show?"
> **Domain expert:** "It should show the latest **Todoist Task Snapshot**. Tasks
> should be requested periodically in the background."

> **Dev:** "If there is no Todoist task snapshot yet, should the overlay still
> show?"
> **Domain expert:** "Yes. Show a simple reminder overlay without task details."

> **Dev:** "Does dismissing the Todoist reminder reset Todoist interaction time?"
> **Domain expert:** "No. Dismiss only arms the repeat cadence; Todoist Interaction
> is reset only by opening Todoist, a Todoist browser visit, or a Todoist task
> change."

> **Dev:** "Does clicking the reminder's open-Todoist action count immediately as
> interaction?"
> **Domain expert:** "Yes. The user explicitly chose Todoist; update interaction
> time immediately instead of waiting for the next monitoring tick."

> **Dev:** "After the open-Todoist action, should cadence or the normal threshold
> decide the next reminder?"
> **Domain expert:** "The normal threshold. Cadence is for dismiss only."

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

> **Dev:** "Does '+20 minutes' extend today's work schedule?"
> **Domain expert:** "No. It is an **Overlay Deferral**: the user stays in
> overtime, but the next overlay is postponed."

> **Dev:** "If the next overlay is due in 12 minutes and the user chooses
> '+30', when is the overlay due?"
> **Domain expert:** "In 42 minutes. **Overlay Deferral** adds to the scheduled
> overlay time, not to the click time."

> **Dev:** "Can the user keep pressing '+5 minutes' forever?"
> **Domain expert:** "No. The **Overlay Deferral Ladder** ends after '+5
> minutes'; after that, the next overlay cannot be deferred."

> **Dev:** "Does showing an overlay consume the next deferral step?"
> **Domain expert:** "No. The **Overlay Deferral Ladder** advances only on an
> explicit **Overlay Deferral** choice."

> **Dev:** "Does deferral replace the normal overlay cadence?"
> **Domain expert:** "No. **Overlay Deferral** only moves the next overlay; after
> an overlay appears, normal cadence and lock escalation continue."

> **Dev:** "If the user stops working for a while and resumes the same evening,
> do deferrals reset?"
> **Domain expert:** "No. The same **Deferral Period** is still active; deferrals
> reset only in the next work period."

> **Dev:** "Can changing the schedule make the current evening stop being
> overtime?"
> **Domain expert:** "No. During the current **Deferral Period**, schedule edits
> become **Pending Period Settings** for a future work period."

> **Dev:** "If WorkGuard restarts, do pending settings become active
> immediately?"
> **Domain expert:** "No. **Current Period Settings** continue to govern the
> active **Deferral Period** until the next work period begins."

> **Dev:** "Should the menu status keep reminding the user about pending
> settings?"
> **Domain expert:** "No. A settings-dialog confirmation is enough; the menu
> should stay focused on current overtime and deferral state."

> **Dev:** "Should the overlay itself offer '+20 minutes'?"
> **Domain expert:** "No. **Overlay Deferral** belongs in the menu via the
> **Contextual Deferral Control**; the overlay is already enforcement."

> **Dev:** "Is there still a pause feature?"
> **Domain expert:** "No. Pause is removed. The **Contextual Deferral Control**
> replaces it; monitoring always stays active."

> **Dev:** "Should the menu item say 'pause overlay'?"
> **Domain expert:** "No. During overtime it should say 'Отложить на N мин'
> (20, 10, or 5); when unavailable, 'пора отдыхать'."

> **Dev:** "Should the deferral menu item disappear when it cannot be used?"
> **Domain expert:** "No. Keep the **Contextual Deferral Control** visible but
> disabled so the unavailable state is explicit."

> **Dev:** "Is the cutoff measured from the original overlay time or the
> currently deferred overlay time?"
> **Domain expert:** "The currently scheduled next overlay time; previous
> **Overlay Deferrals** move the cutoff with the overlay."

## Flagged Ambiguities

- "LaunchAgent target" was used for both `/Applications/WorkGuard.app` and
  direct Python. Resolved: installed login startup opens the **Supported GUI
  target**; direct Python remains a **Debug launch**.
- "User action data" could mean local guidance facts or exportable telemetry.
  Resolved: future behavior uses local coarse **Activity Signals**; data leaves
  the machine only after an **Explicit User Request**, and **Sensitive Secrets**
  never leave except for **Authorized Credential Use**.
- "Todoist token storage" could mean `config.json`. Resolved: token lives in a
  gitignored **Local Secret Environment File**.
- "Todoist engagement" could mean productivity, task completion, or general work.
  Resolved: use **Todoist Interaction** for direct contact with Todoist; unrelated
  work activity does not count.
- "Opened Todoist" could mean the app is merely running. Resolved: app signal is
  frontmost-only.
- "Browser visit" could require proving the active tab. Resolved: a recorded
  `todoist.com` History visit is enough.
- "User away" could mean the reminder should wait for computer activity. Resolved:
  during work time, inactivity still counts as **Todoist Non-Interaction Time**.
- "Lunch" or "break" could mean pausing the reminder timer. Resolved: breaks are
  not modeled; inside work time the timer is wall-clock.
- "Morning grace" could mean waiting `idle_threshold_min` after `work_start`.
  Resolved: no morning grace; first check in a work period can show the reminder if
  there was no **Todoist Interaction** within the threshold before that check.
- "API task change time" could mean when WorkGuard noticed the diff. Resolved: use
  **Todoist Change Time** when available.
- "Cold start snapshot" could mean no engagement is recorded. Resolved: active
  tasks with fresh `updated_at` count as interaction on cold start.
- "Any Todoist change" could include system-generated recurring reschedules.
  Resolved: **System Todoist Change** does not count as **Todoist Interaction**.
- "Moved/reordered task" could be ignored because content did not change. Resolved:
  task move and reorder events count as **Todoist Interaction**.
- "Task disappeared from active tasks" could be ignored because active snapshot has
  no timestamp. Resolved: query completed/deleted Todoist sources and use their
  event timestamps.
- "Completed/deleted lookback" could be unbounded. Resolved: threshold plus poll
  interval plus five-minute buffer is enough for reminder recency.
- "API failed" could mean possible hidden Todoist activity. Resolved: a failed
  signal is an **Unavailable Todoist Signal**, not **Todoist Interaction**.
- "Enabled Todoist reminder" could mean API token is mandatory. Resolved: the
  enabled flag activates local app/browser signals; the token only adds API
  access.
- "Dashboard data" could mean live fetch at overlay time. Resolved: dashboard uses
  the latest **Todoist Task Snapshot** refreshed periodically in the background.
- "No task snapshot" could mean no overlay. Resolved: show the reminder overlay
  without task details.
- "Dismiss reminder" could mean the user engaged with Todoist. Resolved: dismiss
  only delays the next reminder by cadence.
- "Open Todoist action" could wait for the next active-app tick. Resolved: clicking
  the action is immediate **Todoist Interaction**.
- "Open Todoist action" could arm repeat cadence. Resolved: it restarts the normal
  threshold; cadence applies to dismiss only.
- "+20 minutes" could mean changing the configured work schedule, pausing
  monitoring, or postponing enforcement. Resolved: it means **Overlay Deferral**
  only.
- "+5 minutes" could mean the smallest repeatable snooze. Resolved: it is the
  final step in the **Overlay Deferral Ladder**, not a repeatable action.
- "Session reset" could mean resetting overtime accounting or resetting deferral
  choices. Resolved: overtime accounting may reset during the day, but the
  **Overlay Deferral Ladder** resets only with the next work-period **Deferral
  Period**.
- "Cannot change settings" could mean the settings UI refuses edits entirely or
  that current enforcement is protected. Resolved: settings edits may be saved as
  **Pending Period Settings**, but must not affect the current **Deferral
  Period**.
- "Pause" in the menu previously meant either monitoring pause or overtime deferral.
  Resolved: monitoring pause is removed; the **Contextual Deferral Control** is the
  only menu control in that region and always performs **Overlay Deferral** or shows
  an unavailable state.

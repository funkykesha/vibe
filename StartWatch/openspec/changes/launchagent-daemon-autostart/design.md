## Context

StartWatch currently allows CLI-side bootstrap of the daemon by launching the menu app bundle when the IPC socket is missing. This mixes ownership across CLI, menu-agent, and daemon processes, leading to duplicate process risk and command races. The target architecture is daemon-first with launchd as the single lifecycle owner.

## Goals / Non-Goals

**Goals:**
- Make daemon lifecycle deterministic via LaunchAgent at user login.
- Provide explicit CLI lifecycle commands (`install`, `uninstall`) for LaunchAgent management.
- Remove app-bundle bootstrap path from CLI/IPC behavior.
- Keep menu-agent operational as UI-only client, including offline daemon UX.
- Ensure daemon handles SIGTERM with graceful shutdown and socket/state cleanup.

**Non-Goals:**
- Redesign service-check logic or check scheduling.
- Replace existing IPC protocol format.
- Add remote management or multi-user launchd orchestration.

## Decisions

1. LaunchAgent label is standardized to `com.startwatch.daemon`.
   - Rationale: clear ownership and separation from legacy `com.user.startwatch`.
   - Alternative considered: keep legacy label. Rejected to avoid long-term ambiguity.

2. Install/uninstall are first-class CLI commands.
   - Rationale: explicit operator workflow for provisioning and rollback.
   - Alternative considered: installer-only flow. Rejected because local/manual setups need direct CLI control.

3. IPC client never launches `.app` as fallback.
   - Rationale: removes race and duplicate process class of bugs.
   - Alternative considered: keep fallback with longer wait/retry. Rejected as non-deterministic.

4. Menu-agent exposes daemon offline state and manual start action.
   - Rationale: preserves UI usability while keeping daemon ownership in launchd.
   - Alternative considered: silent no-op when daemon offline. Rejected due to poor diagnosability.

5. SIGTERM is routed into existing daemon shutdown path.
   - Rationale: one shutdown path reduces divergence between user-initiated and launchd-initiated stops.
   - Alternative considered: immediate exit on signal. Rejected because it may leave stale socket/state.

## Risks / Trade-offs

- [Risk] LaunchAgent path mismatch to deployed binary can cause failed starts.
  - Mitigation: validate `ProgramArguments` in `doctor` and during `install`.
- [Risk] Users with legacy label may run parallel jobs.
  - Mitigation: `install/uninstall` perform legacy cleanup (`com.user.startwatch`) as migration step.
- [Risk] Menu actions while daemon is offline may appear broken.
  - Mitigation: explicit menu item/status and action to kickstart daemon.
- [Risk] Signal handling may conflict with existing exit flow.
  - Mitigation: keep `shutdown()` idempotent and reuse existing cleanup sequence.

## Context

StartWatch uses one binary for daemon, menu UI, and CLI, but startup ownership is currently ambiguous across app launch, launchd, and direct CLI invocation. The requested behavior is one user-visible contract: same effective startup result and same effective shutdown result regardless of entrypoint.

Three failure-prone areas must be explicitly addressed:
- startup race when launchd and app launch overlap,
- app launch while headless daemon already owns socket,
- quit behavior when menu process is not daemon owner.

## Goals / Non-Goals

**Goals:**
- Make daemon ownership race-safe using bind-first arbitration.
- Support two full-mode runtime shapes: local owner+UI and UI-only client attached to existing daemon.
- Unify menu actions (including Quit) through one control interface that works for local and remote ownership.
- Preserve headless daemon mode and LaunchAgent persistence.

**Non-Goals:**
- Add new LaunchAgent for menu process.
- Redesign checks, notifications, or service config schema.
- Remove IPC protocol used by CLI.

## Decisions

### Decision 1: Ownership arbitration is bind-first
- Choice: process first attempts to bind IPC socket; bind outcome decides owner/non-owner role.
  - bind success => owner.
  - bind `EADDRINUSE` => non-owner unless stale socket is proven.
  - `EADDRINUSE` + failed handshake => remove stale socket once and retry bind once.
- Why: avoids TOCTOU race from separate “socket exists?” pre-check.
- Alternative considered: pre-check socket then start server. Rejected as race-prone.

### Decision 2: Startup uses role-driven flow
- Choice: `startApp(showMenu:)` branches on ownership result:
  - owner + `showMenu=true` => start local coordinator and menu UI.
  - owner + `showMenu=false` => start headless coordinator.
  - non-owner + `showMenu=false` => exit duplicate daemon process.
  - non-owner + `showMenu=true` => start UI-only client mode connected via IPC.
- Why: preserves single daemon ownership while keeping app launch usable.
- Alternative considered: always create local coordinator in full mode. Rejected because daemon may already be active.

### Decision 3: Menu control uses local/remote abstraction
- Choice: menu delegate depends on a control protocol with two implementations:
  - LocalControl: direct coordinator calls.
  - RemoteControl: IPC client requests to owner daemon.
- Why: Quit and service actions stay identical across owner and client UI modes.
- Alternative considered: optional coordinator + ad-hoc branching. Rejected due to lifecycle bugs.

### Decision 4: Quit always targets daemon shutdown path
- Choice: menu Quit uses control abstraction:
  - local mode => direct shutdown.
  - remote mode => `.quit` command over IPC.
- Why: guarantees equivalent stop semantics with `startwatch stop`.
- Alternative considered: menu client just closes UI. Rejected as behavior mismatch.

### Decision 5: LaunchAgent remains single daemon launcher
- Choice: keep one daemon LaunchAgent with `/usr/local/bin/startwatch daemon --no-menu`.
- Why: launchd owns persistence; app launch remains interactive entrypoint.
- Alternative considered: second menu LaunchAgent. Rejected for this change scope.

## Risks / Trade-offs

- [Risk] False stale-socket cleanup could disrupt valid owner process.  
  → Mitigation: only unlink after failed connection/handshake and single retry limit.

- [Risk] Remote UI control may drift from local behavior.  
  → Mitigation: shared control protocol contract and parity tests for key actions.

- [Risk] Simultaneous startup can still produce transient failed attempts.  
  → Mitigation: explicit duplicate-headless exit and deterministic non-owner UI client fallback.

- [Trade-off] Full mode is no longer always in-process coordinator+UI.  
  → Benefit: correct behavior when daemon ownership already established by launchd.

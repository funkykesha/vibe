## Context

StartWatch currently routes service control through daemon IPC callbacks, but start/restart flows do not carry a typed service outcome back to caller contexts. We need a clean split where daemon remains headless and UI contexts perform terminal actions only when daemon returns explicit terminal intent.

## Goals / Non-Goals

**Goals:**
- Add request/response semantics for IPC service control (`startService`, `restartService`).
- Introduce explicit config toggle `background: Bool?` to decide daemon-managed background launch vs interactive terminal intent.
- Keep CLI interactive start/restart in current terminal (`ServiceRunner.exec`) and avoid opening extra terminal windows.
- Ensure menu-agent executes terminal-launch code on main thread.

**Non-Goals:**
- Rework `restartAllFailed` behavior.
- Change terminal backend implementations (iTerm/Warp/Terminal adapters).
- Add cross-version IPC compatibility between different binary releases.

## Decisions

1. **Typed service response over existing socket**
- Decision: introduce `IPCServiceResponse` with `.ok`, `.executeInTerminal(TerminalCommand)`, `.error(String)`.
- Rationale: minimal shape that covers background, interactive, and failure paths.
- Alternative considered: keep one-way IPC and add side-channel files; rejected as harder to reason about and test.

2. **Scope request/response to single-service start/restart**
- Decision: wire request/response only for `startService` and `restartService`.
- Rationale: this is where terminal intent is needed.
- Alternative: migrate all IPC actions now; rejected to keep blast radius small.

3. **CLI behavior split by `background`**
- Decision: `background == true` uses daemon IPC response; interactive path keeps current `ServiceRunner.exec` in caller terminal.
- Rationale: avoids launching duplicate terminal windows from CLI.
- Alternative: CLI uses `TerminalLauncher`; rejected as UX regression.

4. **Main-thread terminal execution in menu-agent**
- Decision: dispatch `.executeInTerminal` handling onto `DispatchQueue.main` before AppKit calls.
- Rationale: AppKit thread-safety requirement.
- Alternative: run on callback thread; rejected due to unsafe UI access risk.

5. **Command string contains cwd composition**
- Decision: daemon builds terminal command string with optional `cd <cwd> && ...` and passes it as `TerminalCommand.command`.
- Rationale: no signature changes in `TerminalLauncher` API.
- Alternative: pass cwd separately through launcher APIs; rejected to keep launcher stable.

## Risks / Trade-offs

- **[IPC wire mismatch between client/server]** → Mitigation: add encode/decode and roundtrip unit tests for new response path.
- **[Behavior drift between daemon and CLI interactive path]** → Mitigation: table-driven tests for `background=true/false` start logic.
- **[UI threading mistakes in menu-agent]** → Mitigation: force main-queue dispatch in one terminal-intent handler.
- **[Breaking IPC across mixed versions]** → Mitigation: document release coupling; deploy CLI+daemon together.

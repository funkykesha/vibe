## Context

Current runtime flow is hybrid:
- `CLI/Menu -> Unix socket -> daemon` for commands
- `daemon -> last_check.json -> Menu/CLI` for status propagation with periodic polling

This creates up to ~3s UI latency, constant background file reads, and split state delivery semantics. The change introduces a single bidirectional socket channel for commands and status events, so menu updates are push-based and near-instant.

Constraints:
- Must preserve current daemon authority over service state.
- Must handle multiple concurrent clients (menu-agent + CLI sessions).
- Must remain resilient to daemon restarts and client disconnects.
- Keep file persistence (`last_check.json`) only as recovery snapshot, not as live transport.

## Goals / Non-Goals

**Goals:**
- Replace menu polling with event-driven IPC push.
- Add message framing to reliably parse stream boundaries.
- Support client subscription model (`subscribe`) and server broadcast (`serviceChanged`).
- Ensure reconnect flow for menu-agent when daemon is temporarily unavailable.
- Keep `startwatch status` path socket-based for live state.

**Non-Goals:**
- Full transport migration to XPC in this phase.
- Redesign of service-check business logic.
- Cross-host/network IPC; scope is local machine only.
- Persisted event log/history stream.

## Decisions

1. Use length-prefixed framing for all IPC messages.
- Decision: encode each frame as `[4-byte big-endian length][JSON payload]`.
- Why: stream sockets do not preserve message boundaries; framing removes message coalescing/splitting ambiguity.
- Alternative considered: newline-delimited JSON.
- Rejected because payload escaping/partial reads are less robust and framing with binary prefix is deterministic.

2. Unify protocol as a single typed `IPCMessage` hierarchy with request and event cases.
- Decision: extend protocol with `subscribe`, `statusSnapshot`, `serviceChanged`, `ok`, `error`, and keep command cases.
- Why: one model for both directions simplifies client/server handling and evolution.
- Alternative considered: separate request and event channels/files.
- Rejected due to duplicated parsing/state logic and lifecycle complexity.

3. Implement daemon-side subscriber registry with broadcast.
- Decision: daemon `IPCServer` tracks active `ClientConnection` instances keyed by connection id; on state changes broadcasts `serviceChanged`.
- Why: enables instant fan-out to all consumers and removes polling dependency.
- Alternative considered: single-client stream with ad-hoc reconnect ownership.
- Rejected because CLI + menu can be active simultaneously.

4. Introduce `ClientConnection` wrapper around file descriptor I/O.
- Decision: encapsulate read loop, decode buffer, send path, and disconnect callbacks.
- Why: isolates low-level fd handling and centralizes framing decode logic.
- Alternative considered: inline fd logic in server/client classes.
- Rejected to avoid duplicated fragile I/O code and memory-leak risk.

5. Menu-agent subscribes and rebuilds UI from push events.
- Decision: on connect, send `.subscribe`, process initial `.statusSnapshot`, then incremental `.serviceChanged`; reconnect with backoff when disconnected.
- Why: keeps menu state synchronized with daemon immediately and safely across daemon restarts.
- Alternative considered: retain polling as fallback path.
- Rejected as it preserves latency and background overhead this phase is removing.

6. Add `IPCTransport` abstraction as compatibility seam.
- Decision: define protocol with `connect`, `disconnect`, request/response send, and event stream; implement with Unix socket transport now.
- Why: de-risks future XPC migration without changing higher-level menu/CLI logic.
- Alternative considered: defer abstraction until XPC work starts.
- Rejected because retrofitting later would increase churn across clients.

## Risks / Trade-offs

- [Risk] Broadcast to slow/stalled clients can block or accumulate backpressure.
  → Mitigation: isolate per-connection send path, evict failing connections on write errors, keep subscriber mutations thread-safe with barrier writes.

- [Risk] Reconnect loops can cause churn when daemon repeatedly flaps.
  → Mitigation: reconnect delay with bounded retry cadence; show explicit offline UI state while disconnected.

- [Risk] Concurrent access to subscriber map introduces race conditions.
  → Mitigation: dedicated concurrent queue + barrier for mutation, snapshot iteration for broadcast.

- [Risk] Framing decode bugs can corrupt stream state.
  → Mitigation: decode from buffered bytes only when complete frame exists; add targeted tests for partial/multiple frames.

- [Risk] Removing polling may expose hidden dependencies on `menu_command.json`/file-based flows.
  → Mitigation: remove file transport paths in this phase, retain `last_check.json` only for startup persistence, and validate CLI/menu flows via socket-only checks.

## Migration Plan

1. Protocol layer:
- Replace/extend shared IPC message definitions with framed codec (`IPCFrame` + unified `IPCMessage` cases).
- Add tests for frame encode/decode (single frame, concatenated frames, partial frame buffering).

2. Server layer:
- Refactor daemon IPC server to accept multiple long-lived connections.
- Add subscriber registration via `.subscribe`.
- Wire service-check updates to `broadcast(.serviceChanged(...))`.

3. Client layer:
- Introduce/upgrade IPC client to maintain connection and consume async events.
- Add reconnect handling and disconnect callback path.

4. Menu-agent integration:
- Remove timer-driven state polling.
- On connect subscribe and handle snapshot + incremental updates.
- Keep offline indicator + reconnect scheduling.

5. CLI integration:
- Route `status` and command acknowledgements through socket protocol, not state file.

6. Cleanup:
- Remove `menu_command.json` transport code paths from codebase.
- Keep `last_check.json` only as persistence artifact for reboot/startup fallback.

Rollback strategy:
- Re-enable previous polling path behind a temporary feature flag or minimal revert of menu-agent transport binding if major regression appears in production.

## Open Questions

- Should `triggerCheck` return immediate `.ok` only, or also a completion event (`checkCompleted`) for clearer CLI UX?
- Do we need ordering/version fields in `serviceChanged` to guard against out-of-order delivery during reconnect windows?
- What retry policy is acceptable for menu reconnect (fixed 5s vs exponential backoff with cap)?
- Should `IPCTransport.send` be strictly request/response, while events are push-only, or do we need correlation ids for multiplexed in-flight CLI calls?

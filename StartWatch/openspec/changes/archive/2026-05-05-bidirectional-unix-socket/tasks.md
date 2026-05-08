## 1. IPC Protocol and Framing

- [x] 1.1 Replace shared IPC message model with unified bidirectional `IPCMessage` cases for commands, snapshots, events, and errors
- [x] 1.2 Implement length-prefixed frame codec (`[4-byte big-endian length][JSON payload]`) with buffered decode for partial and concatenated frames
- [x] 1.3 Add/adjust protocol tests for single frame, multi-frame stream, partial frame buffering, and malformed payload handling

## 2. Daemon Socket Server and Subscriber Fan-Out

- [x] 2.1 Refactor daemon IPC server to accept multiple concurrent persistent Unix socket connections
- [x] 2.2 Ensure daemon binds to `~/.local/state/startwatch/sock` and removes stale socket file before bind to avoid `EADDRINUSE` after crashes
- [x] 2.3 Add subscriber registry handling for `subscribe` and immediate `statusSnapshot` response
- [x] 2.4 Broadcast `serviceChanged` only on effective state changes (operational state + error message), excluding timestamp/latency fields
- [x] 2.5 Ensure failed/disconnected subscribers are evicted during broadcast without breaking delivery to remaining clients

## 3. Client Connection and Transport Abstraction

- [x] 3.1 Add `ClientConnection` wrapper for fd lifecycle, read loop, frame decode loop, and safe send path
- [x] 3.2 Introduce `IPCTransport` abstraction and Unix socket implementation to isolate transport concerns
- [x] 3.3 Implement CLI request/response behavior so one-off CLI calls close connection after response and do not stay subscribed

## 4. Menu-Agent Event-Driven Integration

- [x] 4.1 Replace timer/file polling state updates in menu-agent with socket subscription flow (`subscribe` → `statusSnapshot` + `serviceChanged`)
- [x] 4.2 Implement daemon disconnect handling with offline UI state and reconnect loop
- [x] 4.3 Implement reconnect backoff (start 2s, cap 60s) and full snapshot-based state rebuild after reconnect
- [x] 4.4 Show staleness indicator when daemon remains unavailable for more than 30 seconds while showing last known state

## 5. Service Checker and State Propagation

- [x] 5.1 Wire service checker/state update path to call IPC server broadcast on changed effective state only
- [x] 5.2 Confirm behavior for multiple service changes in one check cycle emits one `serviceChanged` event per changed service

## 6. Cleanup and Backward Compatibility

- [x] 6.1 Remove file-based live transport code paths (`menu_command.json` and timer-driven file reads for live updates)
- [x] 6.2 Keep `last_check.json` only as persistence snapshot, not live IPC transport
- [x] 6.3 Verify legacy CLI behavior when daemon is unavailable remains graceful (no crash, clear unavailable state)

## 7. Validation and Regression Coverage

- [x] 7.1 Add integration tests for daemon restart/reconnect, stale socket recovery, and subscriber cleanup on disconnect
- [x] 7.2 Add/adjust tests for `startwatch status` socket path and non-subscriber CLI lifecycle
- [x] 7.3 Run `swift test` and validate all tests pass before marking change ready for archive

## 1. IPC response contract

- [x] 1.1 Add `IPCServiceResponse` and `TerminalCommand` models for service-control responses.
- [x] 1.2 Implement `IPCClient.sendAndReceive(...)` for `startService`/`restartService` while keeping one-way send path for other commands.
- [x] 1.3 Update `IPCServer` dispatch/write flow to return typed response on service-control requests before closing socket.

## 2. Daemon and config behavior

- [x] 2.1 Add `background: Bool?` to `ServiceConfig` decode/validation path.
- [x] 2.2 Update daemon `onStartService`/`onRestartService` callbacks to return `IPCServiceResponse` based on `background`.
- [x] 2.3 Build interactive terminal intent command string in daemon (including optional `cd <cwd> && ...` composition).

## 3. Caller-side handling

- [x] 3.1 Update `StartCommand` to use IPC response only for `background == true`; keep interactive path on `ServiceRunner.exec(...)`.
- [x] 3.2 Update restart single-service path to follow same background/interactive split.
- [x] 3.3 Update menu-agent service actions to handle `executeInTerminal` on `DispatchQueue.main` before calling `TerminalLauncher`.

## 4. Verification

- [x] 4.1 Add unit tests for IPC response encode/decode and client/server service-control roundtrip.
- [x] 4.2 Add unit tests for daemon decision table (`background=true` => `.ok`, otherwise `.executeInTerminal`).
- [x] 4.3 Add CLI command tests for `StartCommand` branch behavior (`background` true vs interactive).
- [x] 4.4 Run `swift test` and perform manual smoke (`launchctl daemon`, menu Start interactive, CLI start interactive/background).
